%%%-------------------------------------------------------------------
%%% @author zhaogang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 30. 三月 2017 17:34
%%%-------------------------------------------------------------------
-module(u_files).
-author("zhaogang").
-include_lib("kernel/include/file.hrl").
%% API
-export([is_file_readable/1]).


%% @spec (Path::string()) -> true | false
is_file_readable(Path) ->
  case file:read_file_info(Path) of
    {ok, FileInfo} ->
      case {FileInfo#file_info.type, FileInfo#file_info.access} of
        {regular, read} -> true;
        {regular, read_write} -> true;
        _ -> false
      end;
    {error, _Reason} ->
      false
  end.