%%%-------------------------------------------------------------------
%%% @author zhaogang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%  Architecture:
%%       top_sup -> zg_listener(sup) -> zg_acceptor(worker)
%%       top_sup -> zg_conn_sup(sup) -> zg_conn
%%% @end
%%% Created : 29. 三月 2017 14:59
%%%-------------------------------------------------------------------
-module(zg_listener).
-author("zhaogang").
-behavior(supervisor).
-include("global_atom.hrl").
-include("zg_logger.hrl").

-define(LITTLEHTTP_OPTS, [
  binary,
  {active, false},
  {backlog, 1024},
  {packet, http_bin},
%%  {raw,6,9,<<1:32/native>>}, %defer accept
  %%{delay_send,true},
  %%{nodelay,true},
  {reuseaddr, true}]
).
-define(EJABBERD_OPTS, [binary,
  {packet, 0},
  {active, false},
  {reuseaddr, true},
  {nodelay, true},
  {send_timeout, 15000},
  {send_timeout_close, true},
  {keepalive, true},
  %% ADD
  {backlog, 256}
]).

%% rabbitmq框架使用的tcp选项
%% -define(TCP_OPTIONS, [binary, {packet, 0}, {active, false},
%%                      {reuseaddr, true}, {nodelay, false}, {delay_send, true},
%%                      {send_timeout, 5000}, {keepalive, false}, {exit_on_close, true}]).
-define(RABBITMQ_OPTS, [
  binary,
  {packet, 0},            %%不设置包头长度
  {active, false},        %% 无法接收数据，直到inet:setopts(Socket, [{active, once}]), 接收一次数据
  {delay_send, true},     %%delay_send是不主动强制send, 而是等socket可写的时候马上就写 延迟发送：{delay_send, true}，聚合若干小消息为一个大消息，性能提升显著
  {nodelay, true},        %%If Boolean == true, the TCP_NODELAY option is turned on for the socket, which means that even small amounts of data will be sent immediately.
  {reuseaddr, true},
  {send_timeout, 5000},    %% 发送超时时间5s
  {high_watermark, 38528},   %% 默认8192 8kb
  {low_watermark, 19264}      %% 默认 4096 4kb
]).


-define(SERVER, ?MODULE).
-define(ACCEPTOR_CHILD(Mod, Seq, Args), {{Mod, Seq}, {Mod, start_link, Args}, temporary, 5000, worker, [Mod]}).
-define(CONNSUP_CHILD(Mod,  Args), {Mod, {Mod, start_link, Args}, permanent, infinity, supervisor, [Mod]}).
%% API
-export([start/0, init/1, start_link/0]).




start_link() ->
  supervisor:start_link({local, ?MODULE}, ?MODULE, []).

start() ->
  Socket_Sup = {?MODULE, {?MODULE, start_link, []}, permanent, 5000, supervisor, [?MODULE]},
  supervisor:start_child(?TOP_SUP, Socket_Sup).



init([]) ->
  LSocket = bind_port(),
%%  根据调度器数量, 启动对应的acceptor
  Schedulers = erlang:system_info(schedulers_online),
  Acceptors = [?ACCEPTOR_CHILD(zg_acceptor, Seq, [[Seq, LSocket]]) || Seq<- lists:seq(1, Schedulers)],
  CONNSUP = ?CONNSUP_CHILD(zg_conn_sup, []),
  {ok, {{one_for_one, 10, 1}, Acceptors ++ [CONNSUP]}}.



bind_port() ->
  Opts = ?LITTLEHTTP_OPTS,
  Port = 6666,
  try check_listener_options(Opts) of
    ok ->
      listen_tcp(Port, Opts)
  catch
    throw:{error, Error} ->
      ?ERROR_MSG(Error, [])
end.




listen_tcp(Port, Opts) ->
  case gen_tcp:listen(Port, Opts) of
    {ok, LSocket} ->
      LSocket;
    Error ->
      erlang:error(Error)
  end.
%%%
%%% Check options
%%%

check_listener_options(Opts) ->
  case includes_deprecated_ssl_option(Opts) of
    false -> ok;
    true ->
      Error = "There is a problem with your ejabberd configuration file: "
      "the option 'ssl' for listening sockets is no longer available."
      " To get SSL encryption use the option 'tls'.",
      throw({error, Error})
  end,
  case certfile_readable(Opts) of
    true -> ok;
    {false, Path} ->
      ErrorText = "There is a problem in the configuration: "
      "the specified file is not readable: ",
      throw({error, ErrorText ++ Path})
  end,
  ok.

%% Parse the options of the socket,
%% and return if the deprecated option 'ssl' is included
%% @spec (Opts) -> true | false
includes_deprecated_ssl_option(Opts) ->
  case lists:keysearch(ssl, 1, Opts) of
    {value, {ssl, _SSLOpts}} ->
      true;
    _ ->
      lists:member(ssl, Opts)
  end.


%% @spec (Opts) -> true | {false, Path::string()}
certfile_readable(Opts) ->
  case proplists:lookup(certfile, Opts) of
    none -> true;
    {certfile, Path} ->
      PathS = binary_to_list(Path),
      case u_files:is_file_readable(PathS) of
        true -> true;
        false -> {false, PathS}
      end
  end.

