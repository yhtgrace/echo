set search_path to mimiciii;

DROP MATERIALIZED VIEW IF EXISTS service_type_MICU_SICU_NSICU CASCADE;

CREATE MATERIALIZED VIEW service_type_MICU_SICU_NSICU AS

with service_type as (
SELECT subject_id, hadm_id, icustay_id, value
  FROM mimiciii.chartevents
  where itemid in (
  '1125'--"Service Type"  carevue
  --'919' --"Service" carevue
  --,'225518'-- "Services (Bronch)" metavision
  --,'225414'--"Home without services", metavision
  --,'225415'--"Home with services" - metavision. 
  ,'224640'--"Service" --metavision
) --and lower(value) in ('micu', 'm', 'md', 'med', 'medicine')  
group by subject_id, hadm_id, icustay_id, value
order by subject_id, hadm_id, icustay_id

)

select *,  
  CASE WHEN value in ('MICU', 'MSICU', 'MICU/SICU') then 1 else 0 END AS MICU,
  CASE WHEN value in ('SICU', 'MSICU', 'T-SICU', 'MICU/SICU') then 1 else 0 END AS SICU,
  CASE WHEN value in ('NSICU') then 1 else 0 END AS NSICU
from service_type
