set search_path to mimiciii;

-- Prerequisite:
-- fluid_cv_dailytotal, fluid_mv_dailytotal, output_dialytotal
-- fluid_dailybalance

DROP MATERIALIZED VIEW IF EXISTS echo_features_fluid CASCADE;

CREATE MATERIALIZED VIEW echo_features_fluid AS

SELECT ef.row_id, ef.subject_id, ef.icustay_id, ef.hadm_id, day_since_admission
--(fd.chartdate - cast(ef.intime as date)) as day_wrt_icuadmit, (fd.chartdate - cast(ef.charttime as date)) as day_wrt_echo, 
,fd.daily_input_ml, fd.daily_output_ml, fd.daily_balance_ml, fd.cumulative_balance_ml -- ef.row_id, ef.icustay_id
    --FROM mimiciii.echo_filter_vars_mx as ef
    FROM mimiciii.echo_icustay as ef
    INNER JOIN mimiciii.fluid_dailybalance fd
        ON ef.icustay_id = fd.icustay_id
--order by fd.subject_id, ef.charttime, day_wrt_echo 
