%%%-------------------------------------------------------------------
%%% @author zhaogang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 05. 四月 2017 14:28
%%%-------------------------------------------------------------------
-module(benchmark_test).
-author("zhaogang").

%% API
-export([http_seq/2, http_con/3]).
-compile(export_all).
%% 并发请求, 并发数, 请求数
http_con(Url, NProcess, N) ->
  inets:start(),
  Pid = spawn(fun() ->
    stats(NProcess)
    end),
  Workers = [spawn(fun() -> req(Url, Pid, round(N/NProcess)) end) || _A<- lists:seq(1, NProcess)],
  timer:sleep(1000),
  io:format("start:~p~n", [erlang:now()]),
  lists:foreach(fun(W) -> W!1 end, Workers).

http_seq(Url, N) ->
  inets:start(),
  F = fun() ->
    case httpc:request(Url) of
      {ok, _} ->
        ok;
      Err ->
        io:format(" ~p~n", [Err])
    end end,
  io:format("start:~p~n", [erlang:now()]),
  [F()  || _A<- lists:seq(1, N)],
  io:format("finish:~p~n", [erlang:now()]).






req(Url, Pid, Times) ->
  receive
    _A ->
      req_url(Url, Pid, Times)
  end.

req_url(Url, Pid, Times) when Times ==0 ->
  Pid ! 1;
req_url(Url, Pid, Times)->
  case httpc:request(Url) of
    {ok, _} ->
      ok;
    Err ->
      io:format(" ~p~n", [Err])
  end,
  req_url(Url, Pid, Times-1).




stats(N) when N == 0 ->
  io:format("finish:~p~n", [erlang:now()]);
stats(N) ->
  receive
    _ ->
      stats(N-1)
  end.