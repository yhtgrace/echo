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

), 

service_type_ as (
select *,  
  CASE WHEN value in ('MICU', 'MSICU', 'MICU/SICU') then 1 else 0 END AS MICU,
  CASE WHEN value in ('SICU', 'MSICU', 'T-SICU', 'MICU/SICU') then 1 else 0 END AS SICU,
  CASE WHEN value in ('NSICU') then 1 else 0 END AS NSICU,
  CASE WHEN value in ('CSRU', 'CSICU', 'CCU', 'CVI/CSRU') then 1 else 0 END AS CARDIAC 
from service_type
) 

-- group by icustay_id
select icustay_id
    ,CASE when sum(MICU) > 0 then 1 else 0 END AS MICU 
    ,CASE when sum(SICU) > 0 then 1 else 0 END AS SICU
    ,CASE WHEN sum(NSICU) > 0 then 1 else 0 END AS NSICU
    ,CASE WHEN sum(CARDIAC) > 0 then 1 else 0 END AS CARDIAC
from service_type_
where icustay_id is not null
group by icustay_id
