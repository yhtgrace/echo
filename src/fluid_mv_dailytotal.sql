set search_path to mimiciii;

DROP MATERIALIZED VIEW IF EXISTS fluid_mv_dailytotal CASCADE;

CREATE MATERIALIZED VIEW fluid_mv_dailytotal AS 

WITH patient_fluid AS 
(
	SELECT *
	FROM mimiciii.inputevents_mv 
	WHERE itemid in (
		'225158' -- NaCl 0.9%
		,'220949' -- Dextrose 5%
		,'225828' -- LR
		,'225823' -- D5 1/2NS
		,'220862' -- Albumin 25%
		,'220970' -- Fresh Frozen Plasma
		,'225159' -- NaCl 0.45%
		,'220864' -- Albumin 5%
		,'226364' -- OR Crystalloid Intake
		,'220995' -- Sodium Bicarbonate 8.4%
		--,'225916' -- TPN w/ Lipids
		,'225825' -- D5NS
		--,'225917' -- TPN without Lipids
		,'225161' -- NaCl 3% (Hypertonic Saline)
		,'225827' -- D5LR
		,'225941' -- D5 1/4NS
		,'226371' -- OR Cryoprecipitate Intake
		,'225171' -- 	Cryoprecipitate
		,'226365' -- 	OR Colloid Intake --------?
		,'226367' -- 	OR FFP Intake ------------?
		,'226375' -- 	PACU Crystalloid Intake---?
		,'226371' -- 	OR Cryoprecipitate Intake--?	
		,'227072' -- 	PACU FFP Intake	-----------?
		-- adding following Matthew's code
		,'220862' --	Albumin 25%
		,'220864' --	Albumin 5%
		,'220970' --	Fresh Frozen Plasma
		,'220995' --	Sodium Bicarbonate 8.4%
		,'225158' --	NaCl 0.9%
		,'225159' --	NaCl 0.45%
		,'225161' --	NaCl 3% (Hypertonic Saline)
		,'225168' --	Packed Red Blood Cells
		,'225170' --	Platelets
		,'225171' --	Cryoprecipitate
		,'225823' --	D5 1/2NS
		,'225825' --	D5NS
		,'225827' --	D5LR
		,'225828' --	LR
		,'226089' --	Piggyback
		,'227531' --	Mannitol
		,'227533' --	Sodium Bicarbonate 8.4% (Amp)
		,'228341' --	NaCl 23.4%
		) 
		and amount > 0  -- amount can be negative, often for REWRITTEN orders.  
		and cancelreason = 0 -- some orders are cancelled
		and statusdescription != 'Rewritten'  -- not sure if this should be a filter.
		and ordercategoryname not like '%Pre Admission%' -- Pre Admission fluid can be very high and cover uncertain amount of time.  
		and icustay_id is not null
		--order by subject_id, starttime
)
, dates AS (
	SELECT row_id, subject_id, icustay_id, hadm_id, rate, amount
	, CASE WHEN starttime::date = d THEN starttime ELSE d END AS starttime
	  , CASE WHEN endtime::date = d THEN endtime ELSE d + 1 END AS endtime
	  FROM patient_fluid t
	  , LATERAL (SELECT d::date
		FROM   generate_series(t.starttime::date, t.endtime::date, interval '1d') d
		) d
	   --ORDER  BY row_id, starttime
)
, dailysplit AS (
	SELECT fl.*, (fl.endtime-fl.starttime) as duration, age(fl.starttime, ic.intime) as elapsed, 
		extract(day from (fl.starttime-ic.intime)) as day_since_admission,
		CASE WHEN rate isnull then amount ELSE rate*extract( epoch from (endtime-starttime)/3600) END as amount_ml
		FROM dates as fl
		join icustays as ic
		on fl.icustay_id = ic.icustay_id
		order by subject_id, icustay_id, starttime
)

--select subject_id, hadm_id, icustay_id, day_since_admission, sum(amount_ml) as dailytotal_ml
select icustay_id, day_since_admission, sum(amount_ml) as dailytotal_ml
from dailysplit
group by day_since_admission, subject_id, icustay_id
order by icustay_id, day_since_admission
