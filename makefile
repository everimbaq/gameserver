#!/usr/bin/env bash
REBAR = ./rebar
LIBDIR = lib
BEAMDIR = lib/ebin
INCLUDEDIR = lib/include
INSTALL = install
LOGDIR = log/
SPOOLDIR = lib/spool
INSTALLUSER = `whoami`

all: compile install

run: co install start
co: compile

deps:
	./rebar get-deps
compile:
	./rebar compile

clean:
	rm -rf deps/*/ebin
	rm -rf lib/*
install:

	# Binary Erlang files
	$(INSTALL) -d $(BEAMDIR)
	$(INSTALL) -m 644 ebin/*.app $(BEAMDIR)
	$(INSTALL) -m 644 ebin/*.beam $(BEAMDIR)
	$(INSTALL) -m 644 deps/*/ebin/*.app $(BEAMDIR)
	$(INSTALL) -m 644 deps/*/ebin/*.beam $(BEAMDIR)

	# ejabberd header files
	$(INSTALL) -d $(INCLUDEDIR)
#	$(INSTALL) -m 644 include/*.hrl $(INCLUDEDIR)
#	todo if include dir not exist?
#	$(INSTALL) -m 644 deps/*/include/*.hrl $(INCLUDEDIR)
#	cp -r deps/*/include/ $(INCLUDEDIR)

	#spool directory
	$(INSTALL) -d -m 750 $(INSTALLUSER) $(SPOOLDIR)
	chmod -R 750 $(SPOOLDIR)

	#log directory
	$(INSTALL) -d -m 750 $(INSTALLUSER) $(LOGDIR)
	chown -R $(INSTALLUSER) $(LOGDIR)
	chmod -R 750 $(LOGDIR)
start:
	$(`pwd`)/start.sh