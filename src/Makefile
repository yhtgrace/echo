#!/usr/bin/make -f

DBNAME=mimic
DBUSER=mimic
SCHEMA=mimiciii

PSQL=psql "dbname=$(DBNAME) options=--search_path=$(SCHEMA)" --username=$(DBUSER)

clean:
	@$(PSQL) -f clean.sql

.PHONY: clean

%: %.sql
	@$(PSQL) -f $<
