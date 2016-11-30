set search_path to mimiciii;

DROP MATERIALIZED VIEW IF EXISTS fluid_dailybalance CASCADE;

CREATE MATERIALIZED VIEW fluid_dailybalance AS 

WITH mv_fluid AS
(
	select fm.subject_id, fm.hadm_id, fm.icustay_id, fm.chartdate, fm.dailytotal_ml as daily_input_ml, o.dailytotal_ml as daily_output_ml, (fm.dailytotal_ml- o.dailytotal_ml) as daily_balance_ml
	from output_dailytotal as o
	join fluid_mv_dailytotal as fm
	on o.subject_id = fm.subject_id and o.chartdate = fm.chartdate 
	-- order by fm.subject_id, fm.chartdate
)
, cv_fluid AS
(
	select fc.subject_id, fc.hadm_id, fc.icustay_id, fc.chartdate, fc.dailytotal_ml as daily_input_ml, o.dailytotal_ml as daily_output_ml, (fc.dailytotal_ml- o.dailytotal_ml) as daily_balance_ml
	from output_dailytotal as o
	join fluid_cv_dailytotal as fc
	on o.subject_id = fc.subject_id and o.chartdate = fc.chartdate 
	-- order by fm.subject_id, fm.chartdate
)

select *
from mv_fluid
union all
select *
from cv_fluid