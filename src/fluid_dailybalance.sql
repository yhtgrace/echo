set search_path to mimiciii;

-- DROP MATERIALIZED VIEW IF EXISTS fluid_dailybalance CASCADE;

CREATE MATERIALIZED VIEW fluid_dailybalance AS 

WITH input AS (
select icustay_id, day_since_admission, dailytotal_ml, 'carevue' as dbsource
from fluid_mv_dailytotal
union all
select icustay_id, day_since_admission, dailytotal_ml, 'metavision' as dbsource
from fluid_cv_dailytotal

), input_dailytotal AS (
select icustay_id, day_since_admission, sum(dailytotal_ml) as dailytotal_input, dbsource
from input
group by icustay_id, day_since_admission, dbsource

)

, balance AS (select i.icustay_id, i.day_since_admission, i.dailytotal_input as daily_input_ml, o.dailytotal_ml as daily_output_ml
,(i.dailytotal_input- o.dailytotal_ml) as daily_balance_ml_pretruncate, dbsource
from output_dailytotal as o
--from output_urine_total as o
join input_dailytotal as i
on o.icustay_id = i.icustay_id and o.day_since_admission = i.day_since_admission
-- order by fm.subject_id, fm.chartdate
)

, balance_truncate as 
(select *, 
CASE 
	WHEN daily_balance_ml_pretruncate > 8000 then 8000 
	WHEN daily_balance_ml_pretruncate < -8000 then -8000
	else daily_balance_ml_pretruncate 
END AS daily_balance_ml,
CASE 
	WHEN daily_balance_ml_pretruncate > 8000 then 1 
	WHEN daily_balance_ml_pretruncate < -8000 then 1
	else 0 
END AS balance_truncated
from balance
)

, cumulative_balance as 
(
select *,
sum(daily_balance_ml) over (partition by icustay_id order by day_since_admission) as cumulative_balance_ml_pretruncate
from balance_truncate
order by icustay_id, day_since_admission
)

select *,
CASE 
	WHEN cumulative_balance_ml_pretruncate > 8000 then 8000 
	WHEN cumulative_balance_ml_pretruncate < -8000 then -8000
	else cumulative_balance_ml_pretruncate 
END AS cumulative_balance_ml
from cumulative_balance






