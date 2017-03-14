drop materialized view if exists procedures cascade;
drop materialized view if exists fluid_preadmission cascade;
drop materialized view if exists fluid_balance_day123 cascade;
drop materialized view if exists fluid_dailybalance cascade;
drop materialized view if exists fluid_mv_dailytotal cascade;
drop materialized view if exists fluid_cv_dailytotal cascade;
drop materialized view if exists output_dailytotal cascade;
drop materialized view if exists service_type_MICU_SICU_NSICU cascade;
drop materialized view if exists ventfeatures cascade;
drop table if exists ventfeatures cascade;
drop materialized view if exists venttype cascade;
drop table if exists venttype cascade;
drop materialized view if exists labs cascade;
drop materialized view if exists secondary_outcomes cascade;
drop materialized view if exists labs_first_day cascade;
drop materialized view if exists d_prescriptions_vaso cascade;
drop materialized view if exists chronic_dialysis cascade;
drop materialized view if exists hard_cardiogenic_filters cascade;
drop table if exists echo_annotations_unique cascade;
drop materialized view if exists icu_features cascade;


--DROP MATERIALIZED VIEW IF EXISTS procedures CASCADE;
--DROP TABLE IF EXISTS echo_annotations_unique CASCADE;
--DROP MATERIALIZED VIEW IF EXISTS d_prescriptions_vaso CASCADE;
--DROP MATERIALIZED VIEW IF EXISTS chronic_dialysis CASCADE;
--DROP MATERIALIZED VIEW IF EXISTS hard_cardiogenic_filters CASCADE;
--DROP MATERIALIZED VIEW IF EXISTS combine_echo_filter_vars CASCADE;
--DROP MATERIALIZED VIEW IF EXISTS d_diagnoses_xc CASCADE;
--DROP MATERIALIZED VIEW IF EXISTS d_diagnoses_xc_annot CASCADE;
--DROP MATERIALIZED VIEW IF EXISTS d_items_labs CASCADE;
--DROP MATERIALIZED VIEW IF EXISTS d_prescriptions CASCADE;
--DROP MATERIALIZED VIEW IF EXISTS d_prescriptions_vaso CASCADE;
--DROP MATERIALIZED VIEW IF EXISTS diagnoses CASCADE;
--DROP MATERIALIZED VIEW IF EXISTS dialysis CASCADE;
--DROP MATERIALIZED VIEW IF EXISTS echo_features CASCADE;
--DROP MATERIALIZED VIEW IF EXISTS echo_features_fluid CASCADE;
--DROP MATERIALIZED VIEW IF EXISTS echo_features_labs CASCADE;
--DROP MATERIALIZED VIEW IF EXISTS echo_features_mx CASCADE;
--DROP MATERIALIZED VIEW IF EXISTS echo_filter_vars CASCADE;
--DROP MATERIALIZED VIEW IF EXISTS echo_filter_vars_mx CASCADE;
--DROP MATERIALIZED VIEW IF EXISTS echo_filtered CASCADE;
--DROP MATERIALIZED VIEW IF EXISTS echo_filtered_MICU CASCADE;
--DROP MATERIALIZED VIEW IF EXISTS echo_filtered_mx CASCADE;
--DROP MATERIALIZED VIEW IF EXISTS echo_icustay CASCADE;
--DROP MATERIALIZED VIEW IF EXISTS echo_outpatient CASCADE;
--DROP MATERIALIZED VIEW IF EXISTS service_type_MICU_SICU_NSICU CASCADE;
--DROP MATERIALIZED VIEW IF EXISTS fluid_balance_day123 CASCADE;
--DROP MATERIALIZED VIEW IF EXISTS fluid_dailybalance_wrt_icuadmission CASCADE;
--DROP MATERIALIZED VIEW IF EXISTS fluid_cv_dailytotal CASCADE;
--DROP MATERIALIZED VIEW IF EXISTS fluid_dailybalance CASCADE;
--DROP MATERIALIZED VIEW IF EXISTS fluid_mv_dailytotal CASCADE;
--DROP MATERIALIZED VIEW IF EXISTS fluid_preadmission CASCADE;
--DROP MATERIALIZED VIEW IF EXISTS hard_cardiogenic_filters CASCADE;
--DROP MATERIALIZED VIEW IF EXISTS icu_features CASCADE;
--DROP MATERIALIZED VIEW IF EXISTS echo_first3day_fluid CASCADE;
--DROP MATERIALIZED VIEW IF EXISTS micu_features CASCADE;
--DROP MATERIALIZED VIEW IF EXISTS output_dailytotal CASCADE;
--DROP MATERIALIZED VIEW IF EXISTS output_urine_total CASCADE;
--DROP MATERIALIZED VIEW IF EXISTS procedures CASCADE;
--DROP MATERIALIZED VIEW IF EXISTS secondary_outcomes CASCADE;
--DROP MATERIALIZED VIEW IF EXISTS test_echo_fluid CASCADE;
--DROP MATERIALIZED VIEW IF EXISTS test_echo_fluid2 CASCADE;
--DROP TABLE IF EXISTS ventfeatures CASCADE;
--DROP TABLE IF EXISTS venttype CASCADE;
--DROP MATERIALIZED VIEW IF EXISTS ventfeatures CASCADE;
--DROP MATERIALIZED VIEW IF EXISTS venttype CASCADE;
--DROP MATERIALIZED VIEW IF EXISTS labs CASCADE;
--DROP MATERIALIZED VIEW IF EXISTS labsfirstday_ CASCADE;
