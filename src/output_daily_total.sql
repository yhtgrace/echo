set search_path to mimiciii;

DROP MATERIALIZED VIEW IF EXISTS output_dailytotal CASCADE;

CREATE MATERIALIZED VIEW output_dailytotal AS 

select subject_id, icustay_id, cast(charttime as date) chartdate, sum(abs(value)) as dailytotal_ml
from outputevents
where itemid != '226633' -- Pre-Admission
and itemid != '40060' --Pre-Admission Output Pre-Admission Output
and value < 100000
group by chartdate, subject_id, icustay_id
order by icustay_id, chartdate
