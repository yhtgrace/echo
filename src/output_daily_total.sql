set search_path to mimiciii;

DROP MATERIALIZED VIEW IF EXISTS output_dailytotal CASCADE;

CREATE MATERIALIZED VIEW output_dailytotal AS 

with fluid_icustay_join as (
select s.icustay_id, s.intime, f.charttime, age(f.charttime, s.intime) as elapsed, value as amount,
  extract(day from (f.charttime-s.intime)) as day_since_admission
from mimiciii.outputevents as f
join mimiciii.icustays as s
on f.icustay_id = s.icustay_id
where itemid != '226633' -- Pre-Admission
and itemid != '40060' --Pre-Admission Output Pre-Admission Output
and value < 100000
and s.icustay_id is not null
)

--select subject_id, icustay_id, day_since_admission, sum(abs(amount)) as dailytotal_ml
select icustay_id, day_since_admission, sum(abs(amount)) as dailytotal_ml
from fluid_icustay_join
group by day_since_admission, icustay_id
