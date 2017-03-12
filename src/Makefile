#!/usr/bin/make -f

DBNAME=mimic
DBUSER=mimic
SCHEMA=mimiciii

PSQL=psql "dbname=$(DBNAME) options=--search_path=$(SCHEMA)" --username=$(DBUSER)

clean:
	@$(PSQL) -f clean.sql

.PHONY: clean

# mimic dependencies: angus_sepsis

all: icu_features

icu_features: d_prescriptions_vaso chronic_dialysis hard_cardiogenic_filters 

#fluid_dailybalance: fluid_mv_dailytotal fluid_cv_dailytotal output_daily_total

#fluid_balance_day123: fluid_dailybalance

%: %.sql
	@$(PSQL) -f $<
