set search_path to mimiciii;

DROP MATERIALIZED VIEW IF EXISTS output_urine_total CASCADE;

CREATE MATERIALIZED VIEW output_urine_total AS 

with fluid_icustay_join as (
select s.icustay_id, s.intime, f.charttime, age(f.charttime, s.intime) as elapsed, value as amount,
  extract(day from (f.charttime-s.intime)) as day_since_admission
from mimiciii.outputevents as f
join mimiciii.icustays as s
on f.icustay_id = s.icustay_id
where value is not null and itemid in (
40055 --;"Urine Out Foley"
,226559 --;"Foley"
,43175 --;"Urine ."
,40069 --;"Urine Out Void"
,226560 --;"Void"
,227510 --;"TF Residual"
,40094 --;"Urine Out Condom Cath"
,40715 --;"Urine Out Suprapubic"
,226561 --;"Condom Cath"
,40473 --;"Urine Out IleoConduit"
,227489 --;"GU Irrigant/Urine Volume Out"
,40085 --;"Urine Out Incontinent"
,40057 --;"Urine Out Rt Nephrostomy"
,40056 --;"Urine Out Lt Nephrostomy"
,226584 --;"Ileoconduit"
,226563 --;"Suprapubic"
,40405 --;"Urine Out Other"
,226564 --;"R Nephrostomy"
,226565 --;"L Nephrostomy"
,40428 --;"Urine Out Straight Cath"
,40096 --;"Urine Out Ureteral Stent #1"
,226557 --;"R Ureteral Stent"
,40651 --;"Urine Out Ureteral Stent #2"
,226558 --;"L Ureteral Stent"
)
and value < 100000
and s.icustay_id is not null
order by icustay_id, charttime, itemid
)

--select subject_id, icustay_id, day_since_admission, sum(abs(amount)) as dailytotal_ml
select icustay_id, day_since_admission, sum(abs(amount)) as dailytotal_ml
from fluid_icustay_join
group by day_since_admission, icustay_id