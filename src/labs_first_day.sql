-- Code from the MIMIC repo, modified to extract labs we care about. 
-- This query pivots lab values taken in the first 24 hours of a patient's stay

-- Have already confirmed that the unit of measurement is always the same: null or the correct unit

DROP MATERIALIZED VIEW IF EXISTS labsfirstday_ CASCADE;

create materialized view labsfirstday_ as

with labs_ as (
    select ls.* 
    from labs ls
    INNER JOIN icustays ic
        ON ic.icustay_id = ls.icustay_id
    WHERE ls.charttime BETWEEN ic.intime and ic.intime + interval '24' hour 
)

select
  pvt.subject_id, pvt.hadm_id, pvt.icustay_id
      
    , avg(case when label = 'ALBUMIN' then valuenum else null end) as LAB_ALBUMIN
    , avg(case when label = 'BICARBONATE' then valuenum else null end) as LAB_BICARBONATE
    , avg(case when label = 'CK-MB' then valuenum else null end) as LAB_CKMB
    , avg(case when label = 'CREATININE' then valuenum else null end) as LAB_CREATININE
    , avg(case when label = 'CRP' then valuenum else null end) as LAB_CRP
    , avg(case when label = 'EGFR' then valuenum else null end) as LAB_EGFR
    , avg(case when label = 'HEMATOCRIT' then valuenum else null end) as LAB_HEMATOCRIT  
    , avg(case when label = 'HEMOGLOBIN' then valuenum else null end) as LAB_HEMOGLOBIN
    , avg(case when label = 'INR' then valuenum else null end) as LAB_INR
    , avg(case when label = 'LACTATE' then valuenum else null end) as LAB_LACTATE
    , avg(case when label = 'PLATELET' then valuenum else null end) AS LAB_PLATELET
    , avg(case when label = 'NTPROBNP' then valuenum else null end) as LAB_NTPROBNP
    , avg(case when label = 'PH' then valuenum else null end) as LAB_PH
    , avg(case when label = 'TROPI' then valuenum else null end) as LAB_TROPI
    , avg(case when label = 'TROPT' then valuenum else null end) as LAB_TROPT
    , avg(case when label = 'WBC' then valuenum else null end) as LAB_WBC

from labs_ pvt
group by pvt.subject_id, pvt.hadm_id, pvt.icustay_id
order by pvt.subject_id, pvt.hadm_id, pvt.icustay_id;
