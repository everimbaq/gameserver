%%%-------------------------------------------------------------------
%%% @author zhaogang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 01. 四月 2017 11:39
%%%-------------------------------------------------------------------
-module(proto_test).
-author("zhaogang").
-include("myuser.hrl").

%% API
-export([test/0]).



test() ->
  Encode = myuser:encode_msg(#'myuser'{id = #'identity'{name="bob", age = 30, family = ["father", "mother"]}, job = [ #job{company=5, title = "leader"}]}),
  Decode = myuser:decode_msg(Encode, 'myuser'),
  io:format("~p ~p", [Encode, Decode]).


