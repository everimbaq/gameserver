%%%-------------------------------------------------------------------
%%% @author zhaogang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 31. 三月 2017 14:03
%%%-------------------------------------------------------------------
-module(player_handler).
-author("zhaogang").


%% gen_server callbacks
-export([init/1,
  handle_call/3,
  handle_cast/2,
  handle_info/2,
  terminate/2]).

-define(SERVER, ?MODULE).

-record(player_state, {tick, login_state}).
-define(PROCESS_TICK, process_tick).%心跳计时
-define(PROCESS_TICK_TIME, 60000).         %心跳间隔时间


%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Initializes the server
%%
%% @spec init(Args) -> {ok, State} |
%%                     {ok, State, Timeout} |
%%                     ignore |
%%                     {stop, Reason}
%% @end
%%--------------------------------------------------------------------
-spec(init(Args :: term()) ->
  {ok, State :: #player_state{}} | {ok, State :: #player_state{}, timeout() | hibernate} |
  {stop, Reason :: term()} | ignore).
init([Socket]) ->
  erlang:start_timer(?PROCESS_TICK_TIME, self(), ?PROCESS_TICK),
  {ok, #player_state{}}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling call messages
%%
%% @end
%%--------------------------------------------------------------------
-spec(handle_call(Request :: term(), From :: {pid(), Tag :: term()},
    State :: #player_state{}) ->
  {reply, Reply :: term(), NewState :: #player_state{}} |
  {reply, Reply :: term(), NewState :: #player_state{}, timeout() | hibernate} |
  {noreply, NewState :: #player_state{}} |
  {noreply, NewState :: #player_state{}, timeout() | hibernate} |
  {stop, Reason :: term(), Reply :: term(), NewState :: #player_state{}} |
  {stop, Reason :: term(), NewState :: #player_state{}}).
handle_call(_Request, _From, State) ->
  {reply, ok, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling cast messages
%%
%% @end
%%--------------------------------------------------------------------
-spec(handle_cast(Request :: term(), State :: #player_state{}) ->
  {noreply, NewState :: #player_state{}} |
  {noreply, NewState :: #player_state{}, timeout() | hibernate} |
  {stop, Reason :: term(), NewState :: #player_state{}}).
handle_cast(_Request, State) ->
  {noreply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling all non call/cast messages
%%
%% @spec handle_info(Info, State) -> {noreply, State} |
%%                                   {noreply, State, Timeout} |
%%                                   {stop, Reason, State}
%% @end
%%--------------------------------------------------------------------
-spec(handle_info(Info :: timeout() | term(), State :: #player_state{}) ->
  {noreply, NewState :: #player_state{}} |
  {noreply, NewState :: #player_state{}, timeout() | hibernate} |
  {stop, Reason :: term(), NewState :: #player_state{}}).

handle_info({timeout, _TimerRef, ?PROCESS_TICK}, State) ->
%%    io:format("tcp timeout tick:~n"),
  erlang:start_timer(?PROCESS_TICK_TIME, self(), ?PROCESS_TICK),
  case State#player_state.tick of
    0 ->
      {stop, normal, State};
    _ ->
      {noreply, State#player_state{tick = 0}}
  end;
%%handle_info({timeout, _TimerRef, {mod, Mod, From, FromModule, Msg}}, State) ->
%%  NewState =
%%    if
%%      State#player_state.login_state =:= ?LOGIN_INIT_DONE ->
%%        case catch Mod:handler_msg(State, From, FromModule, Msg) of
%%          {throw, ErrCode} ->
%%            err_code_proto:err_code(State, {mod, Mod, From, FromModule, Msg}, {throw, ErrCode});
%%          State -> State
%%        end;
%%      true ->
%%        State
%%    end,
%%  {noreply, NewState};
handle_info(_Info, State) ->
  {noreply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% This function is called by a gen_server when it is about to
%% terminate. It should be the opposite of Module:init/1 and do any
%% necessary cleaning up. When it returns, the gen_server terminates
%% with Reason. The return value is ignored.
%%
%% @spec terminate(Reason, State) -> void()
%% @end
%%--------------------------------------------------------------------
-spec(terminate(Reason :: (normal | shutdown | {shutdown, term()} | term()),
    State :: #player_state{}) -> term()).
terminate(_Reason, _State) ->
  ok.



%%%===================================================================
%%% Internal functions
%%%===================================================================
