-- labs of interest from d_labitems

DROP MATERIALIZED VIEW IF EXISTS d_labs_all CASCADE;

CREATE MATERIALIZED VIEW d_labs_all AS 

WITH dl AS (
    SELECT * 
    FROM d_labitems
    WHERE itemid IN ( 
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
, di AS (
    SELECT *
    FROM d_items
    WHERE label ~* '.*albumin.*'
)
SELECT * FROM di; 
