%%%-------------------------------------------------------------------
%%% @author zhaogang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 01. 四月 2017 15:32
%%%-------------------------------------------------------------------
-module(nif_example).
-author("zhaogang").

%% API
-export([test/0]).

-on_load(init/0).
-export([foo/1, bar/1]).


init() ->
  ok = erlang:load_nif("lib/so/nif_example", 0).


%% foo和bar函数的逻辑在nif_example.c中实现
foo(_X) ->
  exit(nif_library_not_loaded).
bar(_Y) ->
  exit(nif_library_not_loaded).

test() ->
  io:format(" foo:~p~n bar:~p~n", [foo(3), bar(5)]).