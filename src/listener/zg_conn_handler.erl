%%%-------------------------------------------------------------------
%%% @author zhaogang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%    player connection 连接和协议处理，不负责逻辑
%%% @end
%%% Created : 30. 三月 2017 19:54
%%%-------------------------------------------------------------------
-module(zg_conn_handler).
-author("zhaogang").
-behavior(gen_server).
-include("zg_logger.hrl").
-define(PROCESS_CALL_MOD, process_callback).  %用户进程回调模块
-define(CONN_LOGIC_HANDLER, player_handler).
-define(TCP_CONNECT_STATE, tcp_connect_state). %进程 tcp连接状态 0.表示初始化 1.表示进程接收到的第一次数据处理完成，可以下发数据
%% API
-export([init/1, start_link/2, start/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

start([SockType, Socket]) ->
  supervisor:start_child(zg_conn_sup, [SockType, Socket]).


start_link(SockType, Socket) ->
  gen_server:start_link(?MODULE, [SockType, Socket], []).

init([_SockType, Socket]) ->
  process_flag(trap_exit, true),
  put(?PROCESS_CALL_MOD, ?CONN_LOGIC_HANDLER),
  put(?TCP_CONNECT_STATE, 0),
  inet:setopts(Socket, [{active, once}]),
  ?CONN_LOGIC_HANDLER:init([Socket]).


handle_call(Request, From, State) ->
  Mod = get(?PROCESS_CALL_MOD),
  Mod:handle_call(Request, From, State).

handle_cast(Request, State) ->
  Mod = get(?PROCESS_CALL_MOD),
  Mod:handle_cast(Request, State).

%% 恶意连接,发大数据,具体最大数据还要测试,暂定40000,(5000　* 8)
handle_info({tcp, _Socket, RecvBin}, State) when bit_size(RecvBin) > 40000 ->
  {stop, {tcp, max_bit}, State};

handle_info({tcp, Socket, RecvBin}, State) ->
  ?DEBUG("socket recv data:~s", [RecvBin]),
  send_data(Socket, RecvBin),
  {noreply, state};
%% 收到tcp数据,握手
%%handle_info({tcp, Socket, RecvBin}, State) ->
%%  ?DEBUG("socket recv data:~s", [RecvBin]),
%%  send_data(Socket, RecvBin),
%%  Ret =
%%    case get(?TCP_CONNECT_STATE) of
%%      0 ->
%%        HeaderList = binary:split(RecvBin, <<"\r\n">>, [global]),
%%        HeaderList1 = [list_to_tuple(binary:split(I, <<": ">>)) || I <- HeaderList, I /= <<>>],
%%
%%        SecWebSocketKey = proplists:get_value(<<"Sec-WebSocket-Key">>, HeaderList1, <<>>),
%%        Sha1 = crypto:hash(sha, [SecWebSocketKey, <<"258EAFA5-E914-47DA-95CA-C5AB0DC85B11">>]),
%%        Base64 = base64:encode(Sha1),
%%        Handshake = [<<"HTTP/1.1 101 Switching Protocols\r\n">>, <<"Upgrade: websocket\r\n">>, <<"Connection: Upgrade\r\n">>,
%%          <<"Sec-WebSocket-Accept: ">>, Base64, <<"\r\n">>, <<"\r\n">>],
%%        send_data(Socket, Handshake),
%%        put(?TCP_CONNECT_STATE, 1),
%%        {noreply, State};
%%
%%      1 ->
%%        Mod = get(?PROCESS_CALL_MOD),
%%        handle_pack(Mod, Socket, RecvBin, State)
%%    end,
%%  inet:setopts(Socket, [{active, once}]),
%%  Ret;

%% 用户正常下线,返回stop即可,析构函数在terminate()中
handle_info({tcp_closed, _Socket}, State) ->
  {stop, normal, State};

handle_info({timeout, _TimerRef, tcp_closed}, State) ->
  {stop, {timeout, tcp_closed}, State};

handle_info(Info, State) ->
  Mod = get(?PROCESS_CALL_MOD),
  Mod:handle_info(Info, State).

%% 进程关闭(包括正常下线,非正常下线都会调用此函数)
terminate(Reason, State) ->
  ?WARNING_MSG("conn process terminating:~p", [Reason]),
  timer:sleep(5000),
  Mod = get(?PROCESS_CALL_MOD),
  Mod:terminate(Reason, State).

code_change(OldVsn, State, Extra) ->
  {ok, State}.


%% 正式接受数据
handle_pack(Mod, Socket, Data, State) ->
  case Data of
    <<_Fin:1, _Rsv:3, 8:4, _Rest/binary>> -> %% 关闭连接
      send_data(Socket, <<1:1, 0:3, 8:4>>),
      {stop, normal, State};
    <<_Fin:1, _Rsv:3, 9:4, _Rest/binary>> -> %% ping,返回pong
      send_data(Socket, <<1:1, 0:3, 9:4>>),
      {noreply, State};
    <<_Fin:1, _Rsv:3, _Opcode:4, _Mask:1, 126:7, Len:16/unsigned-big-integer, Rest/binary>> ->
      handle_pack(Mod, Socket, Len, Rest, State);
    <<_Fin:1, _Rsv:3, _Opcode:4, _Mask:1, 127:7, Len:32/unsigned-big-integer, Rest/binary>> ->
      handle_pack(Mod, Socket, Len, Rest, State);
    <<_Fin:1, _Rsv:3, _Opcode:4, _Mask:1, Len:7, Rest/binary>> ->
      handle_pack(Mod, Socket, Len, Rest, State);
    _ ->
      ?DEBUG("tcp websocket RecvBin init error:~p~n", [Data]),
      {noreply, State}
  end.

handle_pack(Mod, Socket, Len, Rest, State) ->
  case Rest of
    <<Masking:4/binary, Payload:Len/binary, Next/binary>> ->
      Str = unmask(Payload, Masking, <<>>),
      case Mod:handle_info({tcp, Socket, Str}, State) of
        {noreply, State2} ->
          case size(Next) of
            0 -> {noreply, State2};
            _Other ->
              handle_pack(Mod, Socket, Next, State2)
          end;
        {stop, _Normal, State} ->
          {stop, normal, State}
      end;
    _ ->
      ?WARNING_MSG("tcp websocket RecvBin error handle_pack/5:~p~n", [Rest]),
      {noreply, State}
  end.


unmask(Payload, Masking = <<MA:8, MB:8, MC:8, MD:8>>, Acc) ->
  case size(Payload) of
    0 -> Acc;
    1 ->
      <<A:8>> = Payload,
      <<Acc/binary, (MA bxor A)>>;
    2 ->
      <<A:8, B:8>> = Payload,
      <<Acc/binary, (MA bxor A), (MB bxor B)>>;
    3 ->
      <<A:8, B:8, C:8>> = Payload,
      <<Acc/binary, (MA bxor A), (MB bxor B), (MC bxor C)>>;
    _Other ->
      <<A:8, B:8, C:8, D:8, Rest/binary>> = Payload,
      Acc1 = <<Acc/binary, (MA bxor A), (MB bxor B), (MC bxor C), (MD bxor D)>>,
      unmask(Rest, Masking, Acc1)
  end.


pack_encode(Bin) ->
  pack_encode(Bin, 1).

pack_encode(Bin, Opcode) ->
  Len = size(Bin),
  case Len of
    Len when Len < 126 ->
      <<1:1, 0:3, Opcode:4, 0:1, Len:7, Bin/binary>>;
    Len when Len < 65535 ->
      <<1:1, 0:3, Opcode:4, 0:1, 126:7, Len:16/unsigned-big-integer, Bin/binary>>;
    Len ->
      <<1:1, 0:3, Opcode:4, 0:1, 127:7, Len:32/unsigned-big-integer, Bin/binary>>
  end.


send_data(Socket, Data) ->
  gen_tcp:send(Socket, Data).