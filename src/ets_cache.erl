%%%-------------------------------------------------------------------
%%% @author zhaogang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 05. 四月 2017 10:42
%%%-------------------------------------------------------------------
-module(ets_cache).
-author("zhaogang").

%% API
-export([start/0]).

-define(tab, test).


start() ->
  ets:new(?tab, [named_table, public]),
  ets:insert(?tab,{key, 0}),
  Pids = [spawn(fun()-> do_read_and_write() end)|| N<-lists:seq(1,10)],
  timer:sleep(1000),
  lists:foreach(fun(Pid)-> Pid!start end, Pids),
  timer:sleep(1000),
  io:format("~p~n", [ets:tab2list(test)]).




%% 多个进程并发读写ets，无法保证数据的准确性
do_read_and_write() ->
  N = case ets:lookup(?tab, key) of
        [{key, V}] ->
          V;
        _ ->
          0
      end,
  receive
    start ->
      ets:insert(?tab, {key, N+5})
  end.

%% update counter可以保证原子性
do_update_counter() ->
  receive
    start ->
      ets:update_counter(test, key, 5)
  end.




