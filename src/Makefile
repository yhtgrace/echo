#!/usr/bin/make -f

DBNAME=mimic
DBUSER=mimic
SCHEMA=mimiciii

PSQL=psql "dbname=$(DBNAME) options=--search_path=$(SCHEMA)" --username=$(DBUSER)

clean:
	@$(PSQL) -f clean.sql

.PHONY: clean

fluid_dailybalance: fluid_mv_dailytotal fluid_cv_dailytotal output_daily_total

fluid_balance_day123: fluid_dailybalance

%: %.sql
	@$(PSQL) -f $<
