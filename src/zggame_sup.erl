-module(zggame_sup).

-behaviour(supervisor).
-include("global_atom.hrl").
%% API
-export([start_link/0]).

%% Supervisor callbacks
-export([init/1]).

%% Helper macro for declaring children of supervisor
-define(CHILD(I, Type), {I, {I, start_link, []}, permanent, 5000, Type, [I]}).

%% ===================================================================
%% API functions
%% ===================================================================

start_link() ->
    supervisor:start_link({local, ?TOP_SUP}, ?MODULE, []).

%% ===================================================================
%% Supervisor callbacks
%% ===================================================================

init([]) ->
  Random = {sv_random, {sv_random, start_link, []}, permanent, 5000, worker, [sv_random]},
    {ok, { {one_for_one, 5, 10}, [Random]} }.

