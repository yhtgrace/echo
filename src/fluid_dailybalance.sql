set search_path to mimiciii;

DROP MATERIALIZED VIEW IF EXISTS fluid_dailybalance CASCADE;

CREATE MATERIALIZED VIEW fluid_dailybalance AS 

WITH input AS (
select *
from fluid_mv_dailytotal
union all
select *
from fluid_cv_dailytotal

), input_dailytotal AS (
select subject_id, hadm_id, icustay_id, chartdate, sum(dailytotal_ml) as dailytotal_input
from input
group by subject_id, hadm_id, icustay_id, chartdate

)

select i.subject_id, i.hadm_id, i.icustay_id, i.chartdate, i.dailytotal_input as daily_input_ml, o.dailytotal_ml as daily_output_ml, (i.dailytotal_input- o.dailytotal_ml) as daily_balance_ml
from output_dailytotal as o
join input_dailytotal as i
on o.subject_id = i.subject_id and o.chartdate = i.chartdate 
-- order by fm.subject_id, fm.chartdate






