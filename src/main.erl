%%%-------------------------------------------------------------------
%%% @author zhaogang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 07. 四月 2017 10:22
%%%-------------------------------------------------------------------
-module(main).
-author("zhaogang").

%% API

-export([start/0]).


start() ->
  {ok,S}= gen_tcp:connect("localhost", 9988, []),
  gen_tcp:send(S, <<"123333333333333333333333333">>).


