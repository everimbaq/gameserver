%%%-------------------------------------------------------------------
%%% @author zhaogang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 01. 四月 2017 18:11
%%%-------------------------------------------------------------------
-module(simple_http_handler).
-author("zhaogang").

%% API
-export([start/1]).


start([SockType, Socket, SchedulerN]) ->
%%  {ok, spawn_opt(fun() -> loop(Socket) end, [link, {scheduler, SchedulerN}])}.
  {ok, spawn(fun() -> loop(Socket) end)}.

loop(S) ->
  case gen_tcp:recv(S, 0) of
    {ok, http_eoh} ->
      Response = <<"HTTP/1.1 200 OK\r\nContent-Length: 12\r\n\r\nhello world!">>,
%%      gen_tcp:send(S, Response),
      erlang:port_command(S, Response, [force]),
      gen_tcp:close(S),
      ok;

    {ok, _Data} ->
      loop(S);
    Error ->
      Error
  end.
