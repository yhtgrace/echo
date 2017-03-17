#!/usr/bin/make -f

DBNAME=mimic
DBUSER=mimic
SCHEMA=mimiciii

PSQL=psql "dbname=$(DBNAME) options=--search_path=$(SCHEMA)" --username=$(DBUSER)

%: %.sql
	@$(PSQL) -f $<

# mimic dependencies: echodata, elixhauser_ahrq, angus_sepsis, apsiii, ventdurations

all: features icu_features fluid_features
	
features: echo_annotations filters lab_features service_type vent_features procedures_features

echo_annotations: create_echo_annotations2
	
filters: d_prescriptions_vaso chronic_dialysis hard_cardiogenic_filters

lab_features: labs secondary_outcomes labs_first_day

vent_features: ventfeatures venttype 

service_type: find_micu_servicetype 

fluid_features: fluid_balance_day123 fluid_preadmission_features 

fluid_dailybalance: fluid_mv_dailytotal fluid_cv_dailytotal output_daily_total

fluid_balance_day123: fluid_dailybalance

fluid_preadmission_features: fluid_preadmission

procedures_features: procedures

.PHONY: clean

clean:
	@$(PSQL) -f clean.sql
