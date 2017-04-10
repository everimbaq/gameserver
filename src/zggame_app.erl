-module(zggame_app).

-behaviour(application).

%% Application callbacks
-export([start/2, stop/1]).
-include("zg_logger.hrl").
%% ===================================================================
%% Application callbacks
%% ===================================================================

start(_StartType, _StartArgs) ->
    %% start logger first
    zg_logger:start(zggame_app),
    write_pid_file(),
    init_mnesia(),
    zg_mysql:start(),
    %% essential app
    start_apps(),
    %% start base services
    start_services(),
    %% cluster and masters
    connect_nodes(),
    start_modules(),
    zggame_sup:start_link(),

    zg_listener:start().

stop(_State) ->
    ok.





%% start dependency apps before self
start_apps() ->
  %% start app softly
  app_man:start_app(crypto),
  app_man:start_app(inets),
  app_man:start_app(ssl).


write_pid_file() ->
  os:getpid()
%% TODO  write pid to file. what's the usage?
 .

start_services() ->
  ok.

connect_nodes() ->
  ok.

start_modules() ->
  ok.


init_mnesia() ->
  MyNode = node(),
  DbNodes = mnesia:system_info(db_nodes),
  case lists:member(MyNode, DbNodes) of
    true ->
      ok;
    false ->
      %% 确保mnesia的node信息和当前的本地存储node是一致的
      ?CRITICAL_MSG("Node name mismatch: I'm [~s], "
      "the database is owned by ~p", [MyNode, DbNodes]),
      ?CRITICAL_MSG("Either set ERLANG_NODE "
      "or change node name in Mnesia", []),
      erlang:error(node_name_mismatch)
  end,
  case mnesia:system_info(extra_db_nodes) of
    [] ->
      %% try to create schema, at least one schema
      mnesia:create_schema([node()]);
    _ ->
      ok
  end,
  app_man:start_app(mnesia),
  mnesia:wait_for_tables(mnesia:system_info(local_tables), infinity).