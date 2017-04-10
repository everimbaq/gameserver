%%%-------------------------------------------------------------------
%%% @author zhaogang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 30. 三月 2017 16:01
%%%-------------------------------------------------------------------
-module(zg_mysql).
-author("zhaogang").
-include("zg_logger.hrl").
-define(SERVER, ?MODULE).
-define(COMMON_EXECUTOR, zg_mysql_pool).
%% API
-export([start/0, test/0]).


start() ->
%%  start zg_mysql as child of top supervisor
%%  ChildSpec = {?SERVER, {?MODULE, start_link, []}, transient, infinity, supervisor, [?MODULE]},
%%  case supervisor:start_child(zggame_sup, ChildSpec) of
%%    {ok, _Pid} ->
%%        ok;
%%    Error ->
%%      ?ERROR_MSG("start mysql supervisor failed:~p", [Error]),
%%      erlang:error("mysql start failed")
%%  end.
  app_man:start_app(emysql),
  %%  TODO dynamic config
  Config = [
    {size, 30},
    {user, "innodealing"},
    {password, "innodealing"},
    {database, "innodealing"},
    {port, 3306},
    {host, "192.168.8.190"},
    {encoding, utf8}
  ],
%%   use different pools for different services
  case emysql:add_pool(?COMMON_EXECUTOR, Config) of
    {error, Error} ->
      Msg = io_lib:format("emysql start failed :~p~n", [Error]),
      erlang:error(Msg);
    _ ->
      test(),
      ok
  end.

test() ->
  ?DEBUG("~p", [emysql:execute(?COMMON_EXECUTOR, <<"select * from users limit 10">>)]).





%% todo
%% CRUD
%% FIELD CHECK
%% SYNTAX CHECK