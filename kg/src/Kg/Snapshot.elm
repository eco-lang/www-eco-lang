module Kg.Snapshot exposing (Snapshot, Header, Base, codec, load, save, formatVersion, emptyBase)

{-| One worktree's snapshot (§11.3 of the plan): the linked graph at the indexed
commit, its history, the search indexes, and what the replay needs to carry on
from there.

A snapshot written with another format or extractor version does not decode,
and is rebuilt.

-}

import Dict exposing (Dict)
import Kg.Codec as C exposing (Codec)
import Kg.Facts as Facts
import Kg.Fs as Fs
import Kg.Graph as Graph exposing (Graph)
import Kg.History as History exposing (History)
import Kg.Search.Bm25 as Bm25
import Kg.Search.Chunks as Chunks exposing (Chunk)
import Set exposing (Set)
import Task exposing (Task)


formatVersion : Int
formatVersion =
    3


type alias Header =
    { worktree : String
    , commit : String
    , packages : String
    , model : String
    , dirty : String
    , concepts : String
    , builtAt : Int
    }


{-| The replay's state at the indexed commit, without the facts, which come
back from the fact cache: the blob of each module-graph file, the blob of each
prose file, the file → node map and the nodes there.
-}
type alias Base =
    { shaOf : Dict String String
    , prose : Dict String String
    , fileNode : Dict String String
    , liveNodes : Set String
    }


emptyBase : Base
emptyBase =
    { shaOf = Dict.empty, prose = Dict.empty, fileNode = Dict.empty, liveNodes = Set.empty }


type alias Snapshot =
    { header : Header
    , base : Base
    , history : History
    , graph : Graph
    , chunks : List Chunk
    , bm25 : Bm25.Index
    }


headerCodec : Codec Header
headerCodec =
    C.record Header
        |> C.field .worktree C.string
        |> C.field .commit C.string
        |> C.field .packages C.string
        |> C.field .model C.string
        |> C.field .dirty C.string
        |> C.field .concepts C.string
        |> C.field .builtAt C.int
        |> C.finish


baseCodec : Codec Base
baseCodec =
    C.record Base
        |> C.field .shaOf (C.dict C.string C.string)
        |> C.field .prose (C.dict C.string C.string)
        |> C.field .fileNode (C.dict C.string C.string)
        |> C.field .liveNodes (C.set C.string)
        |> C.finish


codec : Codec Snapshot
codec =
    C.withHeader "ECOKG" (formatVersion * 1000 + Facts.extractorVersion) <|
        (C.record Snapshot
            |> C.field .header headerCodec
            |> C.field .base baseCodec
            |> C.field .history History.codec
            |> C.field .graph Graph.codec
            |> C.field .chunks (C.list Chunks.codec)
            |> C.field .bm25 Bm25.codec
            |> C.finish
        )


load : String -> Task x (Maybe Snapshot)
load path =
    Fs.readBytesMaybe path |> Task.map (Maybe.andThen (C.decode codec))


save : String -> Snapshot -> Task String ()
save path snap =
    Fs.writeAtomic path (C.encode codec snap)
