%%%-------------------------------------------------------------------
%%% @author zhaogang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%  accept a conn and callback to its handler
%%% @end
%%% Created : 30. 三月 2017 19:37
%%%-------------------------------------------------------------------
-module(zg_acceptor).
-author("zhaogang").
-include("zg_logger.hrl").
%% API
-export([start_link/1, init/2]).
%%-define(CallBack, zg_conn_handler).
-define(CallBack, simple_http_handler).
start_link([SchedulerN, LSocket]) ->
  proc_lib:start_link(?MODULE, init, [SchedulerN, LSocket], infinity, [{scheduler, SchedulerN}, {priority, high}]).


init(SchedulerN, ListenSocket) ->
  proc_lib:init_ack({ok, self()}),
  accept(SchedulerN, ListenSocket).


accept(SchedulerN, ListenSocket) ->
  case gen_tcp:accept(ListenSocket, infinity) of
    {ok, Socket} ->
%%          check_socket(ListenSocket, Socket),
          case ?CallBack:start([gen_tcp, Socket, SchedulerN]) of
            {ok, Pid} ->
              gen_tcp:controlling_process(Socket, Pid);
            {error, Error}->
              ?ERROR_MSG("client handler start failed:~p", [Error])
          end;
        Else ->
          ?WARNING_MSG("unexpected socket ~p",
            [Else])
      end,
  flush(),
  accept(SchedulerN, ListenSocket).

check_socket(ListenSocket, Socket) ->
  case {inet:sockname(Socket), inet:peername(Socket)} of
    {{ok, {Addr, Port}}, {ok, {PAddr, PPort}}} ->
          ?DEBUG("(~w) Accepted connection ~s:~p -> ~s:~p",
            [Socket, inet_parse:ntoa(PAddr), PPort,
              inet_parse:ntoa(Addr), Port]);
    {error, Reason} ->
      ?ERROR_MSG("(~w) Failed TCP accept: ~w",
        [ListenSocket, Reason]),
      throw("socket error")
  end.

flush() ->
  receive Msg ->
    error_logger:error_msg(
      "acceptor received unexpected message: ~p~n",
      [Msg]),
    flush()
  after 0 ->
    ok
  end.