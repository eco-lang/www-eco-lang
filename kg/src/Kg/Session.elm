module Kg.Session exposing (Session, open, refresh, view, freshnessLine)

{-| A worktree's graph as the tools see it: the snapshot, brought up to date
before every query (§12.2 of the plan), and the overlay of uncommitted files
(§12.3).
-}

import Array
import Dict
import Kg.Assemble exposing (ConceptSpec)
import Kg.Context exposing (Context)
import Kg.Fs as Fs
import Kg.Git as Git
import Kg.Link exposing (PackageKernels)
import Kg.Overlay as Overlay exposing (Overlay)
import Kg.Snapshot as Snapshot exposing (Snapshot)
import Kg.Tools as Tools
import Kg.Update as Update
import Task exposing (Task)
import Time


type alias Session =
    { ctx : Context
    , packages : PackageKernels
    , concepts : List ConceptSpec
    , snapshot : Snapshot
    , overlay : Maybe Overlay
    , stale : Maybe String
    , checkedAt : Int
    }


{-| Loads the snapshot, building or updating it as needed. -}
open : Context -> PackageKernels -> List ConceptSpec -> Update.Progress -> Task String Session
open ctx packages concepts progress =
    Snapshot.load ctx.paths.snapshot
        |> Task.andThen
            (\existing ->
                let
                    session snap =
                        { ctx = ctx, packages = packages, concepts = concepts, snapshot = snap, overlay = Nothing, stale = Nothing, checkedAt = 0 }
                in
                case existing of
                    Just snap ->
                        refresh progress (session snap)

                    Nothing ->
                        locked ctx progress (Update.build ctx packages concepts progress)
                            |> Task.andThen (\snap -> refresh progress (session snap))
            )


locked : Context -> Update.Progress -> Task String Snapshot -> Task String Snapshot
locked ctx progress make =
    Fs.withLock ctx.paths.lock 30000 (make |> Task.andThen (\snap -> Snapshot.save ctx.paths.snapshot snap |> Task.map (\_ -> snap)))
        |> Task.andThen
            (\r ->
                case r of
                    Fs.Locked snap ->
                        Task.succeed snap

                    Fs.Busy ->
                        -- another process is updating; take what it wrote
                        Snapshot.load ctx.paths.snapshot
                            |> Task.andThen
                                (\s ->
                                    case s of
                                        Just snap ->
                                            Task.succeed snap

                                        Nothing ->
                                            Task.fail "another kg process is building the snapshot"
                                )
            )


{-| The freshness check: HEAD and the dirty files against the snapshot. A
changed HEAD updates the snapshot; changed dirty files rebuild the overlay.
A failure leaves the session as it was, marked stale.
-}
refresh : Update.Progress -> Session -> Task String Session
refresh progress s =
    Git.head s.ctx.worktree
        |> Task.andThen
            (\head ->
                (if head == s.snapshot.header.commit then
                    Task.succeed s

                 else
                    -- another process may have updated it already
                    Snapshot.load s.ctx.paths.snapshot
                        |> Task.andThen
                            (\onDisk ->
                                case onDisk of
                                    Just snap ->
                                        if snap.header.commit == head then
                                            Task.succeed { s | snapshot = snap, overlay = Nothing }

                                        else
                                            locked s.ctx progress (Update.update s.ctx s.packages s.concepts progress (Just snap) |> Task.map (Maybe.withDefault snap))
                                                |> Task.map (\new -> { s | snapshot = new, overlay = Nothing })

                                    Nothing ->
                                        locked s.ctx progress (Update.build s.ctx s.packages s.concepts progress)
                                            |> Task.map (\new -> { s | snapshot = new, overlay = Nothing })
                            )
                )
                    |> Task.andThen (\s2 -> Overlay.refresh s2.ctx s2.packages s2.concepts progress s2.snapshot s2.overlay |> Task.map (\o -> { s2 | overlay = o }))
            )
        |> Task.andThen (\s2 -> Time.now |> Task.map (\t -> { s2 | stale = Nothing, checkedAt = Time.posixToMillis t }))
        |> Task.onError (\e -> Task.succeed { s | stale = Just e })


freshnessLine : Session -> String
freshnessLine s =
    let
        snap =
            s.snapshot

        date =
            Array.get (Array.length snap.history.commits - 1) snap.history.commits
                |> Maybe.map (\c -> Tools.isoDate c.time)
                |> Maybe.withDefault ""
    in
    "graph at " ++ String.left 10 snap.header.commit ++ (if date /= "" then " · " ++ date else "")
        ++ (case s.overlay of
                Just o ->
                    " · includes " ++ String.fromInt o.fileCount ++ " uncommitted file" ++ (if o.fileCount == 1 then "" else "s")

                Nothing ->
                    ""
           )
        ++ (case s.stale of
                Just why ->
                    " · stale: update failed: " ++ String.left 200 why

                Nothing ->
                    ""
           )


view : Session -> Tools.View
view s =
    case s.overlay of
        Just o ->
            { graph = o.graph, history = s.snapshot.history, chunks = Array.fromList o.chunks, bm25 = o.bm25, freshness = freshnessLine s }

        Nothing ->
            { graph = s.snapshot.graph, history = s.snapshot.history, chunks = Array.fromList s.snapshot.chunks, bm25 = s.snapshot.bm25, freshness = freshnessLine s }
