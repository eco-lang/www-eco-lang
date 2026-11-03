module Mcp.Protocol exposing
    ( Incoming(..), Tool, ToolResult, ServerInfo
    , decode, handle, Action(..)
    , result, error, toolResult, textResult, errorResult
    , protocolVersion
    )

{-| The MCP messages the server speaks: JSON-RPC 2.0, one message per line, at
protocol revision 2025-11-25 (the initialize-based era).

Pure: `decode` turns a line into an `Incoming`, and `handle` decides what to do
with it. Answers to everything but tool calls are made here; a tool call is
handed back as `CallTool` for the server to run.

Every request this server does not know, `server/discover` among them, gets
-32601 at once. Claude Code then falls back to `initialize`.

-}

import Json.Decode as D
import Json.Encode as E


protocolVersion : String
protocolVersion =
    "2025-11-25"


type Incoming
    = Request { id : E.Value, method : String, params : E.Value }
    | Notification { method : String }
    | Response
    | Malformed String


type alias Tool =
    { name : String, description : String, inputSchema : E.Value }


type alias ToolResult =
    { text : String, isError : Bool }


type alias ServerInfo =
    { name : String, version : String, instructions : String }


type Action
    = Reply String
    | CallTool { id : E.Value, name : String, arguments : E.Value }
    | NoReply


decode : String -> Incoming
decode line =
    case D.decodeString D.value line of
        Err e ->
            Malformed (D.errorToString e)

        Ok v ->
            let
                field name dec =
                    D.decodeValue (D.field name dec) v
            in
            case ( field "method" D.string, field "id" D.value ) of
                ( Ok method, Ok id ) ->
                    Request
                        { id = id
                        , method = method
                        , params = field "params" D.value |> Result.withDefault (E.object [])
                        }

                ( Ok method, Err _ ) ->
                    Notification { method = method }

                ( Err _, Ok _ ) ->
                    Response

                ( Err _, Err _ ) ->
                    Malformed "neither a request, a notification nor a response"


handle : ServerInfo -> List Tool -> Incoming -> Action
handle info tools incoming =
    case incoming of
        Malformed why ->
            Reply (error E.null -32700 ("Parse error: " ++ String.left 200 why))

        Notification _ ->
            NoReply

        Response ->
            NoReply

        Request req ->
            case req.method of
                "initialize" ->
                    Reply
                        (result req.id
                            (E.object
                                [ ( "protocolVersion", E.string protocolVersion )
                                , ( "capabilities", E.object [ ( "tools", E.object [ ( "listChanged", E.bool False ) ] ) ] )
                                , ( "serverInfo", E.object [ ( "name", E.string info.name ), ( "version", E.string info.version ) ] )
                                , ( "instructions", E.string info.instructions )
                                ]
                            )
                        )

                "ping" ->
                    Reply (result req.id (E.object []))

                "tools/list" ->
                    Reply (result req.id (E.object [ ( "tools", E.list encodeTool tools ) ]))

                "tools/call" ->
                    case D.decodeValue (D.field "name" D.string) req.params of
                        Ok name ->
                            if List.any (\t -> t.name == name) tools then
                                CallTool
                                    { id = req.id
                                    , name = name
                                    , arguments =
                                        D.decodeValue (D.field "arguments" D.value) req.params
                                            |> Result.withDefault (E.object [])
                                    }

                            else
                                Reply (error req.id -32602 ("Unknown tool: " ++ name))

                        Err _ ->
                            Reply (error req.id -32602 "tools/call needs a tool name")

                _ ->
                    Reply (error req.id -32601 "Method not found")


encodeTool : Tool -> E.Value
encodeTool t =
    E.object
        [ ( "name", E.string t.name )
        , ( "description", E.string t.description )
        , ( "inputSchema", t.inputSchema )
        ]


result : E.Value -> E.Value -> String
result id value =
    E.encode 0 (E.object [ ( "jsonrpc", E.string "2.0" ), ( "id", id ), ( "result", value ) ])


error : E.Value -> Int -> String -> String
error id code message =
    E.encode 0
        (E.object
            [ ( "jsonrpc", E.string "2.0" )
            , ( "id", id )
            , ( "error", E.object [ ( "code", E.int code ), ( "message", E.string message ) ] )
            ]
        )


toolResult : E.Value -> ToolResult -> String
toolResult id r =
    result id
        (E.object
            ([ ( "content", E.list identity [ E.object [ ( "type", E.string "text" ), ( "text", E.string r.text ) ] ] ) ]
                ++ (if r.isError then
                        [ ( "isError", E.bool True ) ]

                    else
                        []
                   )
            )
        )


textResult : String -> ToolResult
textResult text =
    { text = text, isError = False }


errorResult : String -> ToolResult
errorResult text =
    { text = text, isError = True }
