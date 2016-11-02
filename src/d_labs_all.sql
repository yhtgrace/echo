-- labs of interest from d_labitems

DROP MATERIALIZED VIEW IF EXISTS d_labs_all CASCADE;

CREATE MATERIALIZED VIEW d_labs_all AS 

WITH dl AS (
    SELECT * 
    FROM d_labitems
    WHERE row_id IN (
         '21' -- pH
        ,'63' -- Albumin
        ,'83' -- Bicarbonate
        ,'90' -- C-Reactive Protein
        ,'488' -- Sedimentation Rate
        ,'113' -- Creatinine
        ,'109' -- CK-MB Index
        ,'111' -- Creatine Kinase (CK)
        ,'112' -- Creatine kinase (MB Isoenzyme)
        ,'121' -- Estimted GFR (MDRD Equation)
        ,'202' -- Troponin I
        ,'203' -- Troponin T
        ,'500' -- WBC Count
        ,'501' -- White Blood Cells
        ,'11' -- Hematocrit, Calculated
        ,'12' -- Hemoglobin
        ,'14' -- Lactate
        ,'164' -- NTProBNP
    )
)
, di AS (
    SELECT *
    FROM d_items
    WHERE category ~* '.*labs.*'
)
SELECT * FROM di; 
