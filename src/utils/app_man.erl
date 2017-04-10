%%%-------------------------------------------------------------------
%%% @author zhaogang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 29. 三月 2017 15:07
%%%-------------------------------------------------------------------
-module(app_man).
-author("zhaogang").

%% API
-export([start_app/1, start_app/2]).

-define(appLevel1, optional).
-define(appLevel2, necessary).

%% softly start app, if it is necessary and start failed, erlang vm will halt.
start_app(App) ->
  start_app(App, ?appLevel1).
start_app(App, StartFlag) when not is_list(App) ->
  start_app([App], StartFlag);
start_app([App|Apps], StartFlag) ->
  case application:start(App) of
    ok ->
      spawn(fun() -> check_app_modules(App, StartFlag) end),
      start_app(Apps);
    {error, {already_started, _}} ->
      start_app(Apps);
    {error, {not_started, DepApp}} ->
      case lists:member(DepApp, [App|Apps]) of
        true ->
          Reason = io_lib:format(
            "failed to start application '~p': "
            "circular dependency on '~p' detected",
            [App, DepApp]),
          exit_or_halt(Reason, StartFlag);
        false ->
          start_app([DepApp,App|Apps], StartFlag)
      end;
    Error ->
      Reason = io_lib:format("failed to start application '~p': ~p", [App, Error]),
      exit_or_halt(Reason, StartFlag)
  end;
start_app([],  _StartFlag) ->
  ok.
exit_or_halt(Reason, StartFlag) ->
  if StartFlag == ?appLevel2->
      halt(string:substr(lists:flatten(Reason), 1, 199));
    true ->
      erlang:error(application_start_failed)
  end.

%% modules listed in app.src must exist in codepath
check_app_modules(App, StartFlag) ->
  {A, B, C} = now(),
  random:seed(A, B, C),
  timer:sleep(2000),
  case application:get_key(App, modules) of
    {ok, Mods} ->
      lists:foreach(
        fun(Mod) ->
          case code:which(Mod) of
            non_existing ->
              File = get_module_file(App, Mod),
              Reason = io_lib:format(
                "couldn't find module ~s "
                "needed for application '~p'",
                [File, App]),
              io:format("3333"),
              exit_or_halt(Reason, StartFlag);
            _ ->
              timer:sleep(10)
          end
        end, Mods);
    _ ->
      %% No modules? This is strange
      ok
  end.

get_module_file(App, Mod) ->
  BaseName = atom_to_list(Mod),
  case code:lib_dir(App, ebin) of
    {error, _} ->
      BaseName;
    Dir ->
      filename:join([Dir, BaseName ++ ".beam"])
  end.