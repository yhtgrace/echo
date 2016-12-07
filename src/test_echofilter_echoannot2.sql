set search_path to mimiciii;
---- Run these first: --
-- echo_filter_vars_mx
-- echo_filtered_mx

DROP MATERIALIZED VIEW IF EXISTS test_echo_fluid2 CASCADE;

CREATE MATERIALIZED VIEW test_echo_fluid2 AS

SELECT ef.*, (fd.chartdate - cast(ef.ed_charttime as date)) as day_wrt_echo, fd.daily_input_ml, fd.daily_output_ml, fd.daily_balance_ml -- ef.row_id, ef.icustay_id
    FROM mimiciii.echo_filtered_mx as ef
    INNER JOIN mimiciii.fluid_dailybalance fd
        ON ef.icustay_id = fd.icustay_id
    --INNER JOIN mimiciii.echo_annotations_unique ea
    --    ON ef.icustay_id = ea.icustay_id 
--order by fd.subject_id, ef.ed_charttime, day_wrt_echo 
