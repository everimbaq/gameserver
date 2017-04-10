%%%-------------------------------------------------------------------
%%% @author zhaogang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 30. 三月 2017 19:56
%%%-------------------------------------------------------------------
-module(zg_conn_sup).
-author("zhaogang").
-behavior(supervisor).
%% API
-export([init/1, start_link/0]).

start_link() ->
  supervisor:start_link({local, ?MODULE}, ?MODULE, zg_conn_handler).

init(ChildMod) ->
  {ok, {{simple_one_for_one, 10, 1},
    [{undefined, {ChildMod, start_link, []}, temporary, brutal_kill, worker, [ChildMod]}]
  }}.