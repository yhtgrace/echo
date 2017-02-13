set search_path to mimiciii;

DROP MATERIALIZED VIEW IF EXISTS fluid_dailybalance CASCADE;

CREATE MATERIALIZED VIEW fluid_dailybalance AS 

WITH input AS (
select icustay_id, day_since_admission, dailytotal_ml
from fluid_mv_dailytotal
union all
select icustay_id, day_since_admission, dailytotal_ml
from fluid_cv_dailytotal

), input_dailytotal AS (
select icustay_id, day_since_admission, sum(dailytotal_ml) as dailytotal_input
from input
group by icustay_id, day_since_admission

)

, balance AS (select i.icustay_id, i.day_since_admission, i.dailytotal_input as daily_input_ml, o.dailytotal_ml as daily_output_ml
,(i.dailytotal_input- o.dailytotal_ml) as daily_balance_ml
from output_dailytotal as o
join input_dailytotal as i
on o.icustay_id = i.icustay_id and o.day_since_admission = i.day_since_admission
-- order by fm.subject_id, fm.chartdate
)

select *,
sum(daily_balance_ml) over (partition by icustay_id order by day_since_admission) as cumulative_balance_ml
from balance
order by icustay_id, day_since_admission





