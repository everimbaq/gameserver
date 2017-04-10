%%%-------------------------------------------------------------------
%%% @author zhaogang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%   config and start lager
%%% @end
%%% Created : 29. 三月 2017 14:36
%%%-------------------------------------------------------------------
-module(zg_logger).
-author("zhaogang").

%% API
-export([start/1, get/0, set/2]).
-define(LOG_PATH, "log/runtime.log").
-include("zg_logger.hrl").
start(App) ->
  application:load(sasl),
  application:set_env(sasl, sasl_error_logger, false),
  application:load(lager),
  ConsoleLog = get_env_app_os(App, log_path, "ENV_LOG_PATH", ?LOG_PATH),
  Dir = filename:dirname(ConsoleLog),
  ErrorLog = filename:join([Dir, "error.log"]),
  CrashLog = filename:join([Dir, "crash.log"]),
  LogRotateDate = get_env_app_os(App, log_rotate_date, "ENV_log_rotate_date",  ""),
  LogRotateSize = get_env_app_os(App, log_rotate_size, "ENV_log_rotate_size", 10*1024*1024),
  LogRotateCount = get_env_app_os(App, log_rotate_count, "ENV_log_rotate_count", 1),
  LogRateLimit = get_env_app_os(App, log_rate_limit, "ENV_log_rate_limit", 100),
  application:set_env(lager, error_logger_hwm, LogRateLimit),
  application:set_env(
    lager, handlers,
    [{lager_console_backend, debug},
      {lager_file_backend, [{file, ConsoleLog}, {level, debug}, {date, LogRotateDate},
        {count, LogRotateCount}, {size, LogRotateSize}]},
      {lager_file_backend, [{file, ErrorLog}, {level, error}, {date, LogRotateDate},
        {count, LogRotateCount}, {size, LogRotateSize}]}]),
  application:set_env(lager, crash_log, CrashLog),
  application:set_env(lager, crash_log_date, LogRotateDate),
  application:set_env(lager, crash_log_size, LogRotateSize),
  application:set_env(lager, crash_log_count, LogRotateCount),
  app_man:start_app(lager),
  test_logger().


%% get env from app.src first
%% if not found, get from os
%% if not found, use default
get_env_app_os(App, AppEnvKey, EnvName, Default) ->
  case application:get_env(App, AppEnvKey) of
    {ok, Path} ->
      Path;
    undefined ->
      case os:getenv(EnvName) of
        false ->
          Default;
        Path ->
          Path
      end
  end.

%% get log level
get() ->
  case lager:get_loglevel(lager_console_backend) of
    none -> {0, no_log, "No log"};
    emergency -> {1, critical, "Critical"};
    alert -> {1, critical, "Critical"};
    critical -> {1, critical, "Critical"};
    error -> {2, error, "Error"};
    warning -> {3, warning, "Warning"};
    notice -> {3, warning, "Warning"};
    info -> {4, info, "Info"};
    debug -> {5, debug, "Debug"}
  end.

%% change log level
set(App, LogLevel) when is_integer(LogLevel) ->
  LagerLogLevel = case LogLevel of
                    0 -> none;
                    1 -> critical;
                    2 -> error;
                    3 -> warning;
                    4 -> info;
                    5 -> debug
                  end,
  case lager:get_loglevel(lager_console_backend) of
    LagerLogLevel ->
      ok;
    _ ->
      ConsoleLog = get_env_app_os(App, log_path, "ENV_LOG_PATH", ?LOG_PATH),
      lists:foreach(
        fun({lager_file_backend, File} = H) when File == ConsoleLog ->
          lager:set_loglevel(H, LagerLogLevel);
          (lager_console_backend = H) ->
            lager:set_loglevel(H, LagerLogLevel);
          (_) ->
            ok
        end, gen_event:which_handlers(lager_event))
  end,
  {module, lager};
set(_App, {_LogLevel, _}) ->
  error_logger:error_msg("custom loglevels are not supported for 'lager'"),
  {module, lager}.

test_logger() ->
  ?INFO_MSG("~p~n", ["This is a message test"]),
  ?WARNING_MSG("~p~n", ["This is a message test"]),
  ?CRITICAL_MSG("~p~n", ["This is a message test"]),
  ?ERROR_MSG("~p~n", ["This is a message test"]),
  ?DEBUG("~p~n", ["This is a message test"]).