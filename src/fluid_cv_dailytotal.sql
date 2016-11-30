set search_path to mimiciii;

DROP MATERIALIZED VIEW IF EXISTS fluid_cv_dailytotal CASCADE;

CREATE MATERIALIZED VIEW fluid_cv_dailytotal AS 

WITH patient_fluid AS 
(
	SELECT *
	FROM mimiciii.inputevents_cv 
	WHERE itemid in (
	'30018'--	.9% Normal Saline
	,'30021'--	Lactated Ringers
	,'30015'--	D5/.45NS
	,'30020'--	.45% Normal Saline
	,'30030'--	Sodium Bicarbonate
	,'30060'--	D5NS
	,'30005'--	Fresh Frozen Plasma
	,'30101'--	OR Crystalloid
	,'30061'--	D5RL
	,'30009'--	Albumin 25%
	,'30190'--	NS .9%
	,'30102'--	OR Colloid
	,'30143'--	3% Normal Saline
	,'30160'--	D5 Normal Saline
	,'30008'--	Albumin 5%
	,'30353'--	0.45% Normal Saline
	,'30159'--	D5 Ringers Lact.
	,'30352'--	0.9% Normal Saline
	,'40850'--	ns bolus
	,'30176'--	.25% Normal Saline
	,'30161'--	.3% normal Saline
	,'42742'--	1/2 NS WITH ,'40 KCL
	,'45206'--	D5W & 3 AMP BICARD
	,'43063'--	NS w/,'40gms CaGluc
	,'41491'--	fluid bolus
	,'45137'--	NS cc/cc
	,'42639'--	bolus
	,'42698'--	NS W/ ,'40 KCL
	,'45321'--	LR w/50meqNAacetate
	,'42244'--	.45ns + 1 amp bicarb
	,'42908'--	NS W/ 20 GM CAGLUC
	,'40865'--	NS BOLUS
	,'42797'--	20Gm CaGluc/1000ccNS
	,'46501'--	H2O Bolus
	,'45358'--	d5ns with ,'40 meqkcl
	,'42297'--	Fluid bolus
	,'42725'--	NS W/ ,'40MEQ KCL
	,'43819'--	1:1 NS Repletion.
	,'41371'--	ns fluid bolus
	,'44504'--	1/2 ns 1/2cc:cc
	,'42832'--	albumin 12.5%
	,'41459'--	1/4 NS
	,'45220'--	ns w/,'40 KCL
	,'46355'--	0.9%NS with ,'40KCL
	,'41490'--	NS bolus
	,'42790'--	ns w/ ,'40meq kcl
	,'46630'--	D10NSS
	,'30181'--	Serum Albumin 5%
	,'44160'--	BOLUS
	,'42288'--	LR w/,'40 kcl
	,'45045'--	WaterBolus
	,'42453'--	Fluid Bolus
	,'44386'--	D5 LR with ,'40mEq K+
	,'42345'--	LR w/ ,'40 mEq
	,'45403'--	albumin
	,'42409'--	D5LR W/,'40K
	,'43406'--	.45 NS
	,'44200'--	FLUID BOLUS
	,'44915'--	D5LR ,'40K
	,'41896'--	ivf boluses
	,'42548'--	NS Bolus
	,'41581'--	Water bolus
	,'41428'--	ns .9% bolus
	,'46564'--	Albumin
	,'40548'--	ALBUMIN
	,'44053'--	normal saline bolus
	,'42844'--	NS fluid bolus
	,'46027'--	NaCl 500+Kcl ,'40
	,'41356'--	IV Bolus
	,'43353'--	Albumin (human) 25%
	,'44521'--	LR bolus
	,'44184'--	LR Bolus
	,'44539'--	D5W W/ NAHCO3 150MEQ
	,'44203'--	Albumin 12.5%
	,'41467'--	NS IV bolus
	,'43169'--	Bicarb drip
	,'44741'--	NS FLUID BOLUS
	,'44367'--	LR
	,'41743'--	water bolus
	,'44983'--	Bolus NS
	,'43237'--	25% Albumin
	,'42265'--	LR W/ 20 KCL
	,'43986'--	iv bolus
	,'44633'--	ns boluses
	,'44126'--	fl bolus
	,'44440'--	Normal Saline Bolus
	,'40423'--	Bolus
	,'44815'--	LR BOLUS
	,'46781'--	lr bolus
	,'44263'--	fluid bolus ns
	,'44426'--	bolus ns
	,'45480'--	500cc ns bolus
	,'41526'--	1/2 ns bolus
	,'41695'--	NS fluid boluses
	,'41237'--	ns fluid boluses
	,'44491'--	.9NS bolus
	,'42749'--	fluid bolus NS
	,'46314'--	NSbolus
	,'45989'--	NS Fluid Bolus
	,'42978'--	D5LR 20KCL
	,'46123'--	ER in NS
	,'45159'--	ER IV NS
	,'44952'--	OR Albumin
	,'41427'--	1/2 nsfluidbolus
	,'44894'--	N/s 500 ml bolus
	,'44439'--	.45NS BOLUS
	,'45073'--	IV fluid bolus
	,'46207'--	OR LR
	,'41380'--	nsbolus
	,'47522.5158'--	.9% Normal Saline
		) 
)
, dates AS (
	SELECT row_id, subject_id, icustay_id, hadm_id, rate, amount
	, CASE WHEN starttime::date = d THEN starttime ELSE d END AS starttime
	  , CASE WHEN endtime::date = d THEN endtime ELSE d +  END AS endtime
	  FROM patient_fluid t
	  , LATERAL (SELECT d::date
		FROM   generate_series(t.starttime::date, t.endtime::date, interval 'd') d
		) d
	   --ORDER  BY row_id, starttime
)
, dailysplit AS (
	SELECT *, (endtime-starttime) as duration, cast(starttime as date) chartdate,
		CASE WHEN rate isnull then amount ELSE rate*extract( epoch from (endtime-starttime)/3600) END as amount_ml
		FROM dates
		order by subject_id, icustay_id, starttime
)

select subject_id, hadm_id, icustay_id, chartdate, sum(amount_ml) as dailytotal_ml
from dailysplit
group by chartdate, subject_id, icustay_id, hadm_id
order by icustay_id, chartdate
