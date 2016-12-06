set search_path to mimiciii;
-- Prerequisite:
-- fluid_cv_dailytotal, fluid_mv_dailytotal, output_dialytotal
-- fluid_dailybalance
-- echo_features_fluid

DROP MATERIALIZED VIEW IF EXISTS echo_first3day_fluid CASCADE;

CREATE MATERIALIZED VIEW echo_first3day_fluid AS

with day1 AS (

select em.row_id, eff.day_wrt_echo, eff.daily_input_ml, eff.daily_output_ml, eff.daily_balance_ml
from echo_icustay em
left join echo_features_fluid eff
on em.row_id = eff.row_id
where day_wrt_echo = 1

), day2 AS (

select em.row_id, eff.day_wrt_echo, eff.daily_input_ml, eff.daily_output_ml, eff.daily_balance_ml
from echo_icustay em
left join echo_features_fluid eff
on em.row_id = eff.row_id
where day_wrt_echo = 2

), day3 AS (

select em.row_id, eff.day_wrt_echo, eff.daily_input_ml, eff.daily_output_ml, eff.daily_balance_ml
from echo_icustay em
left join echo_features_fluid eff
on em.row_id = eff.row_id
where day_wrt_echo = 3
)

,composite as (
select em.row_id
,d1.daily_input_ml as day1_input_ml, d1.daily_output_ml as day1_output_ml, d1.daily_balance_ml as day1_balance_ml
,d2.daily_input_ml as day2_input_ml, d2.daily_output_ml as day2_output_ml, d2.daily_balance_ml as day2_balance_ml
,d3.daily_input_ml as day3_input_ml, d3.daily_output_ml as day3_output_ml, d3.daily_balance_ml as day3_balance_ml
from echo_icustay em
left join day1 as d1
on em.row_id = d1.row_id
left join day2 as d2
on em.row_id = d2.row_id
left join day3 as d3
on em.row_id = d3.row_id
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