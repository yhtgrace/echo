DROP MATERIALIZED VIEW IF EXISTS echo_features CASCADE;

CREATE MATERIALIZED VIEW echo_features AS

WITH admission_chart AS (

SELECT DISTINCT ON(ce.icustay_id, ce.itemid, ce.valuenum) ce.icustay_id 
    ,ce.charttime AS item_charttime
    ,ce.valuenum AS item_valuenum
    ,ce.itemid AS item_itemid
    ,ce.valueuom AS item_valueuom
    ,ef.intime AS item_intime
FROM chartevents ce
LEFT JOIN echo_filter ef
    ON ce.icustay_id = ef.icustay_id
    WHERE (
        ce.itemid IN ('1394', '226707', '226730')
    )
)

, echo_features AS (

    SELECT ef.row_id, ef.icustay_id

      -- demographics
        ,pt.subject_id -- subject_id
        ,pt.gender -- gender
        ,ef.age_at_intime -- age at admission to ICU
        -- height
        -- weight
        ,am.insurance -- insurance type
        ,am.ethnicity -- ethnicity

    FROM echo_filter ef 
    INNER JOIN icustays ic
        ON ef.icustay_id = ic.icustay_id
    INNER JOIN patients pt
        ON ic.subject_id = pt.subject_id
    INNER JOIN admissions am
        ON ef.hadm_id = am.hadm_id

) 

SELECT * FROM admission_chart
