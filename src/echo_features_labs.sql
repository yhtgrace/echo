DROP MATERIALIZED VIEW IF EXISTS echo_features_labs CASCADE;

CREATE MATERIALIZED VIEW echo_features_labs AS 

WITH labs AS (

  SELECT ef.row_id, ef.subject_id, ef.hadm_id, ef.icustay_id
  -- absolute time difference echo chart time and lab chart time 
    , greatest(le.charttime, ef.charttime) - least(le.charttime, ef.charttime) as abs_dt
  -- here we assign labels to ITEMIDs
  -- this also fuses together multiple ITEMIDs containing the same data
    , case
        when itemid = 50862 then 'ALBUMIN'
        when itemid = 50882 then 'BICARBONATE'
        when itemid = 50908 then 'CK-MB'
        when itemid = 50912 then 'CREATININE'
        when itemid = 50889 then 'CRP'
        when itemid = 50920 then 'EGFR'
        when itemid = 50810 then 'HEMATOCRIT'
        when itemid = 51221 then 'HEMATOCRIT'
        when itemid = 50811 then 'HEMOGLOBIN'
        when itemid = 51222 then 'HEMOGLOBIN'
        when itemid = 51237 then 'INR'
        when itemid = 50813 then 'LACTATE'
        when itemid = 50963 then 'NTPROBNP'
        when itemid = 50820 then 'PH'
        when itemid = 51265 then 'PLATELET'
        when itemid = 51002 then 'TROPI'
        when itemid = 51003 then 'TROPT'
        when itemid = 51300 then 'WBC'
        when itemid = 51301 then 'WBC'
      else null
    end as label
    , -- add in some sanity checks on the values
    -- the where clause below requires all valuenum to be > 0, 
    -- so these are only upper limit checks
     case
      when itemid = 50862 and valuenum >    10 then null -- g/dL 'ALBUMIN'
      when itemid = 50882 and valuenum > 10000 then null -- mEq/L 'BICARBONATE'
      when itemid = 50912 and valuenum >   150 then null -- mg/dL 'CREATININE'
      when itemid = 50810 and valuenum >   100 then null -- % 'HEMATOCRIT'
      when itemid = 51221 and valuenum >   100 then null -- % 'HEMATOCRIT'
      when itemid = 50811 and valuenum >    50 then null -- g/dL 'HEMOGLOBIN'
      when itemid = 51222 and valuenum >    50 then null -- g/dL 'HEMOGLOBIN'
      when itemid = 50813 and valuenum >    50 then null -- mmol/L 'LACTATE'
      when itemid = 51265 and valuenum > 10000 then null -- K/uL 'PLATELET'
      when itemid = 51237 and valuenum >    50 then null -- 'INR'
      when itemid = 51300 and valuenum >  1000 then null -- 'WBC'
      when itemid = 51301 and valuenum >  1000 then null -- 'WBC'
    else le.valuenum
    end as valuenum

  FROM echo_icustay ef

  LEFT JOIN labevents le
    on le.subject_id = ef.subject_id and le.hadm_id = ef.hadm_id
    and le.ITEMID in
    (
      -- comment is: LABEL | CATEGORY | FLUID 
      50862, -- ALBUMIN | CHEMISTRY | BLOOD 
      50882, -- BICARBONATE | CHEMISTRY | BLOOD
      50908, -- CK-MB INDEX | CHEMISTRY | BLOOD
      50912, -- CREATININE | CHEMISTRY | BLOOD
      50889, -- C-REACTIVE PROTEIN | CHEMISTRY | BLOOD
      50920, -- ESTIMATED GFR | CHEMISTRY | BLOOD
      51221, -- HEMATOCRIT | HEMATOLOGY | BLOOD
      50810, -- HEMATOCRIT, CALCULATED | BLOOD GAS | BLOOD 
      51222, -- HEMOGLOBIN | HEMATOLOGY | BLOOD  
      50811, -- HEMOGLOBIN | BLOOD GAS | BLOOD
      51237, -- INR(PT) | HEMATOLOGY | BLOOD
      50813, -- LACTATE | BLOOD GAS | BLOOD
      51265, -- PLATELET COUNT | HEMATOLOGY | BLOOD 
      50963, -- NTPROBNP | CHEMISTRY | BLOOD
      50820, -- PH | BLOOD GAS | BLOOD
      51002, -- TROPONIN I | CHEMISTRY | BLOOD
      51003, -- TROPONIN T | CHEMISTRY | BLOOD
      51301, -- WHITE BLOOD CELLS | HEMATOLOGY | BLOOD 
      51300  -- WBC COUNT | HEMATOLOGY | BLOOD 
    )
    -- lab values cannot be 0 and cannot be negative
    and valuenum is not null and valuenum > 0 
) 
, labs_ AS (

    SELECT ls.row_id, ls.label, ls.abs_dt
      -- average labs if more than 1 available per row id
      , avg(ls.valuenum) AS valuenum
    FROM labs ls
    group by ls.row_id, ls.label, ls.abs_dt
)
-- for each row and each lab, get the closest lab
, closest_lab_ AS (
    SELECT ls.row_id, ls.label, min(ls.abs_dt) AS min_abs_dt
    FROM labs_ ls
    GROUP BY ls.row_id, ls.label
)
-- a really silly way to do argmin
, closest_lab AS (
    SELECT ls.row_id, ls.label, ls.valuenum
    FROM labs_ ls
    INNER JOIN closest_lab_ cl 
        ON ls.row_id = cl.row_id
        AND ls.label = cl.label
        AND ls.abs_dt = cl.min_abs_dt
)
, summary_labs AS (
    SELECT row_id 
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
    FROM closest_lab
    GROUP BY row_id

)
SELECT * FROM summary_labs
