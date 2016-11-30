set search_path to mimiciii;

DROP MATERIALIZED VIEW IF EXISTS output_dailytotal CASCADE;

CREATE MATERIALIZED VIEW output_dailytotal AS 

select subject_id, hadm_id, icustay_id, cast(charttime as date) chartdate, sum(abs(value)) as dailytotal_ml
from outputevents
group by chartdate, subject_id, icustay_id, hadm_id
order by icustay_id, chartdate
