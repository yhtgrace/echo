-- Code from the MIMIC repo, modified to extract labs we care about. 

-- Have already confirmed that the unit of measurement is always the same: null or the correct unit

DROP MATERIALIZED VIEW IF EXISTS labs CASCADE;

create materialized view labs as
( -- begin query that extracts the data
  select ie.subject_id, ie.hadm_id, ie.icustay_id, le.charttime
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

  from icustays ie

  left join labevents le
    on le.subject_id = ie.subject_id and le.hadm_id = ie.hadm_id
    --and (le.charttime between (ie.intime - interval '6' hour) and (ie.outtime + interval '6' hour))
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
) 
