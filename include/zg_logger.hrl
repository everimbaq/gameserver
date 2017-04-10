%%%-------------------------------------------------------------------
%%% @author zhaogang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 30. 三月 2017 12:01
%%%-------------------------------------------------------------------
-author("zhaogang").

-define(color_none, "\e[m").
-define(color_red, "\e[1m\e[31m").
-define(color_yellow, "\e[1m\e[33m").
-define(color_green, "\e[0m\e[32m").
-define(color_black, "\e[0;30m").
-define(color_blue, "\e[0;34m").
-define(color_purple, "\e[0;35m").
-define(color_cyan, "\e[0;36m").
-define(color_white, "\e[0;37m").


-compile([{parse_transform, lager_transform}]).
-define(DEBUG(Format, Args),
  lager:debug(?color_none ++ Format  ++ ?color_none, Args)).

-define(INFO_MSG(Format, Args),
  lager:info(?color_green ++ Format  ++ ?color_none, Args)).

-define(WARNING_MSG(Format, Args),
  lager:warning(?color_yellow ++ Format ++ ?color_none, Args)).

-define(ERROR_MSG(Format, Args),
  lager:error(?color_red ++ Format  ++ ?color_none, Args)).

-define(CRITICAL_MSG(Format, Args),
  lager:critical(?color_yellow ++ Format  ++ ?color_none, Args)).