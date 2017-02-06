set search_path to mimiciii;

-- Prerequisite:
-- fluid_cv_dailytotal, fluid_mv_dailytotal, output_dialytotal
-- fluid_dailybalance

DROP MATERIALIZED VIEW IF EXISTS fluid_dailybalance_wrt_icuadmission CASCADE;

CREATE MATERIALIZED VIEW fluid_dailybalance_wrt_icuadmission AS

SELECT ic.row_id, ic.subject_id, ic.icustay_id, ic.hadm_id, ic.intime, fd.chartdate, (fd.chartdate - cast(ic.intime as date)) as day_wrt_icuadmit, fd.daily_input_ml, fd.daily_output_ml, fd.daily_balance_ml
    FROM mimiciii.icustays as ic
    INNER JOIN mimiciii.fluid_dailybalance fd
        ON ic.icustay_id = fd.icustay_id
