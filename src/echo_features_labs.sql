-- get labs of interest 
-- at time of admission to ICU, at time of echo, at discharge from ICU

-- do a preliminary check that labs are available
-- that is, for each lab, count the number of unique hadm_ids

DROP MATERIALIZED VIEW IF EXISTS echo_features_labs CASCADE;

CREATE MATERIALIZED VIEW echo_features_labs AS

WITH labs AS (

    SELECT ef.row_id, ef.icustay_id, ef.hadm_id, ef.subject_id
        ,ef.echo_charttime
        ,le.charttime AS lab_charttime
        ,le.charttime - ef.echo_charttime AS dt
        ,GREATEST(le.charttime, ef.echo_charttime) - 
            LEAST(le.charttime, ef.echo_charttime) AS abs_dt
        ,di.itemid AS labid
        ,le.valuenum
        ,le.valueuom
        ,le.flag
    FROM echo_features ef
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
, closest_lab AS (
    SELECT ls.row_id, ls.labid, MIN(abs_dt) AS min_abs_dt
    FROM labs ls
    GROUP BY ls.row_id, ls.labid
)
, creatinine_lab AS (
    SELECT DISTINCT ON (ls.row_id) ls.row_id
        ,ls.lab_charttime AS lab_creatinine_charttime
        ,ls.dt AS lab_creatinine_dt
        ,ls.valuenum AS lab_creatinine_valuenum
        ,ls.valueuom AS lab_creatinine_valueuom
        ,ls.flag AS lab_creatinine_flag
    FROM closest_lab cl
    INNER JOIN labs ls
        ON ls.row_id = cl.row_id
        AND ls.abs_dt = cl.min_abs_dt
        AND ls.labid = cl.labid
    WHERE ls.labid = '50912' -- Creatinine
)
, wbc_lab AS (
    SELECT DISTINCT ON (ls.row_id) ls.row_id
        ,ls.lab_charttime AS lab_wbc_charttime
        ,ls.dt AS lab_wbc_dt
        ,ls.valuenum AS lab_wbc_valuenum
        ,ls.valueuom AS lab_wbc_valueuom
        ,ls.flag AS lab_wbc_flag
    FROM labs ls
    INNER JOIN closest_lab cl
        ON cl.row_id = ls.row_id
        AND cl.min_abs_dt = ls.abs_dt
        AND cl.labid = ls.labid
    WHERE ls.labid = '51301' -- White Blood Cells 
)
, echo_features_labs AS (
    SELECT cl.row_id 
        
        -- creatinine 
        ,cl.lab_creatinine_charttime
        ,cl.lab_creatinine_dt
        ,cl.lab_creatinine_valuenum
        ,cl.lab_creatinine_valueuom
        ,cl.lab_creatinine_flag
        
        -- wbc 
        ,wl.lab_wbc_charttime
        ,wl.lab_wbc_dt
        ,wl.lab_wbc_valuenum
        ,wl.lab_wbc_valueuom
        ,wl.lab_wbc_flag

    FROM creatinine_lab cl
    FULL OUTER JOIN wbc_lab wl
        ON cl.row_id = wl.row_id
)
SELECT * FROM closest_lab
