set search_path to mimiciii;
-- Prerequisite:
-- fluid_cv_dailytotal, fluid_mv_dailytotal, output_dialytotal
-- fluid_dailybalance
-- fluid_dailybalance_wrt_icuadmission (fluid_balance_wrt_icuadmission.sql)

DROP MATERIALIZED VIEW IF EXISTS fluid_balance_day123 CASCADE;

CREATE MATERIALIZED VIEW fluid_balance_day123 AS

with day1 AS (

select ic.row_id, fb.day_since_admission, fb.daily_input_ml, fb.daily_output_ml, fb.daily_balance_ml, fb.cumulative_balance_ml, fb.balance_truncated
from icustays ic
left join fluid_dailybalance fb
on ic.icustay_id = fb.icustay_id
where day_since_admission = 0

), day2 AS (
select ic.row_id, fb.day_since_admission, fb.daily_input_ml, fb.daily_output_ml, fb.daily_balance_ml, fb.cumulative_balance_ml, fb.balance_truncated
from icustays ic
left join fluid_dailybalance fb
on ic.icustay_id = fb.icustay_id
where day_since_admission = 1

), day3 AS (
select ic.row_id, fb.day_since_admission, fb.daily_input_ml, fb.daily_output_ml, fb.daily_balance_ml, fb.cumulative_balance_ml, fb.balance_truncated
from icustays ic
left join fluid_dailybalance fb
--on ic.row_id = fb.row_id
on ic.icustay_id = fb.icustay_id
where day_since_admission = 2
)

,composite as (
select ic.row_id, ic.subject_id, ic.icustay_id, ic.hadm_id
,d1.daily_input_ml as day1_input_ml, d1.daily_output_ml as day1_output_ml, d1.cumulative_balance_ml as day1_balance_ml
,d2.daily_input_ml as day2_input_ml, d2.daily_output_ml as day2_output_ml, d2.cumulative_balance_ml as day2_balance_ml
,d3.daily_input_ml as day3_input_ml, d3.daily_output_ml as day3_output_ml, d3.cumulative_balance_ml as day3_balance_ml
,CASE 
  WHEN d1.balance_truncated=1 then 1
  WHEN d2.balance_truncated=1 then 1
  WHEN d2.balance_truncated=1 then 1
  ELSE 0
  END AS balance_truncated
from icustays ic
left join day1 as d1
on ic.row_id = d1.row_id
left join day2 as d2
on ic.row_id = d2.row_id
left join day3 as d3
on ic.row_id = d3.row_id
order by row_id
)

select * from composite
order by row_id

--select row_id, count(*)
--from composite
--group by row_id
--order by count desc
-- examples of multiple row_ids returned: 102893, 98656, 71214
-- corresponding subject_id               31300, 30376
-- these patients have multiple entries per day for fluid input, 


--select * 
--from composite
--where row_id = 98656