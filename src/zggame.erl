%%%-------------------------------------------------------------------
%%% @author zhaogang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 29. 三月 2017 14:04
%%%-------------------------------------------------------------------
-module(zggame).
-author("zhaogang").

%% API
-export([start/0]).
-define(app, zggame).
-include("zg_logger.hrl").
start() ->
  case application:start(?app) of
    ok ->
      ?INFO_MSG("Application ~p started ~n", [?app]);
    {error, Reason} ->
      ?ERROR_MSG("Application ~p start failed:~p ~n", [?app, Reason])
  end.