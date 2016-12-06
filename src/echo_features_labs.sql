DROP MATERIALIZED VIEW IF EXISTS echo_features_labs CASCADE;

CREATE MATERIALIZED VIEW echo_features_labs AS 

SELECT
  pvt.row_id

  , min(case when label = 'ALBUMIN' then valuenum else null end) as LAB_ALBUMIN_min
  , max(case when label = 'ALBUMIN' then valuenum else null end) as LAB_ALBUMIN_max
  , min(case when label = 'BICARBONATE' then valuenum else null end) as LAB_BICARBONATE_min
  , max(case when label = 'BICARBONATE' then valuenum else null end) as LAB_BICARBONATE_max
  , min(case when label = 'CK-MB' then valuenum else null end) as LAB_CKMB_min
  , max(case when label = 'CK-MB' then valuenum else null end) as LAB_CKMB_max
  , min(case when label = 'CREATININE' then valuenum else null end) as LAB_CREATININE_min
  , max(case when label = 'CREATININE' then valuenum else null end) as LAB_CREATININE_max
  , min(case when label = 'CRP' then valuenum else null end) as LAB_CRP_min
  , max(case when label = 'CRP' then valuenum else null end) as LAB_CRP_max
  , min(case when label = 'EGFR' then valuenum else null end) as LAB_EGFR_min
  , max(case when label = 'EGFR' then valuenum else null end) as LAB_EGFR_max
  , min(case when label = 'HEMATOCRIT' then valuenum else null end) as LAB_HEMATOCRIT_min
  , max(case when label = 'HEMATOCRIT' then valuenum else null end) as LAB_HEMATOCRIT_max
  , min(case when label = 'HEMOGLOBIN' then valuenum else null end) as LAB_HEMOGLOBIN_min
  , max(case when label = 'HEMOGLOBIN' then valuenum else null end) as LAB_HEMOGLOBIN_max
  , min(case when label = 'INR' then valuenum else null end) as LAB_INR_min
  , max(case when label = 'INR' then valuenum else null end) as LAB_INR_max
  , min(case when label = 'LACTATE' then valuenum else null end) as LAB_LACTATE_min
  , max(case when label = 'LACTATE' then valuenum else null end) as LAB_LACTATE_max
  , min(case when label = 'PLATELET' then valuenum else null end) AS LAB_PLATELET_min
  , max(case when label = 'PLATELET' then valuenum else null end) AS LAB_PLATELET_max
  , min(case when label = 'NTPROBNP' then valuenum else null end) as LAB_NTPROBNP_min
  , max(case when label = 'NTPROBNP' then valuenum else null end) as LAB_NTPROBNP_max
  , min(case when label = 'PH' then valuenum else null end) as LAB_PH_min
  , max(case when label = 'PH' then valuenum else null end) as LAB_PH_max
  , min(case when label = 'TROPI' then valuenum else null end) as LAB_TROPI_min
  , max(case when label = 'TROPI' then valuenum else null end) as LAB_TROPI_max
  , min(case when label = 'TROPT' then valuenum else null end) as LAB_TROPT_min
  , max(case when label = 'TROPT' then valuenum else null end) as LAB_TROPT_max
  , min(case when label = 'WBC' then valuenum else null end) as LAB_WBC_min
  , max(case when label = 'WBC' then valuenum else null end) as LAB_WBC_max


FROM
( -- begin query that extracts the data
  SELECT ef.row_id, ef.subject_id, ef.hadm_id, ef.icustay_id
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
  -- the where clause below requires all valuenum to be > 0, so these are only upper limit checks
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

  --FROM echo_filter_vars ef
  FROM echo_icustay ef

  LEFT JOIN labevents le
    on le.subject_id = ef.subject_id and le.hadm_id = ef.hadm_id
    -- specify the time period
    and le.charttime between (le.charttime - interval '12' hour) and (le.charttime + interval '12' hour)
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
    and valuenum is not null and valuenum > 0 -- lab values cannot be 0 and cannot be negative
) pvt
group by pvt.row_id, pvt.subject_id, pvt.hadm_id, pvt.icustay_id
order by pvt.row_id, pvt.subject_id, pvt.hadm_id, pvt.icustay_id

