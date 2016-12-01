-- get labs of interest 
-- at time of admission to ICU, at time of echo, at discharge from ICU

-- do a preliminary check that labs are available
-- that is, for each lab, count the number of unique hadm_ids

DROP MATERIALIZED VIEW IF EXISTS echo_features_labs CASCADE;

CREATE MATERIALIZED VIEW echo_features_labs AS

WITH labs AS (

    SELECT ef.row_id, ef.icustay_id, ef.hadm_id, ef.subject_id 
        ,le.charttime
        ,di.label
    FROM echo_filtered ef
    INNER JOIN labevents le
        ON le.hadm_id = ef.hadm_id
    INNER JOIN d_labitems di
        ON di.itemid = le.itemid
    WHERE le.itemid IN ( 
             '50820' -- pH
            ,'50862' -- Albumin
            ,'50889' -- Bicarbonate
            ,'50889' -- C-Reactive Protein
            ,'51288' -- Sedimentation Rate
            ,'50912' -- Creatinine
            ,'50908' -- CK-MB Index
            ,'50910' -- Creatine Kinase (CK)
            ,'50911' -- Creatine kinase (MB Isoenzyme)
            ,'50920' -- Estimted GFR (MDRD Equation)
            ,'51002' -- Troponin I
            ,'51003' -- Troponin T
            ,'51300' -- WBC Count
            ,'51301' -- White Blood Cells
            ,'50810' -- Hematocrit, Calculated
            ,'50811' -- Hemoglobin
            ,'50813' -- Lactate
            ,'50963' -- NTProBNP
    )
)

SELECT * FROM labs
