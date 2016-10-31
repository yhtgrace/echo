-- Extract information about icustays where the icustay_id/hadm_id is associated with 
-- an echo. Filter hadm_ids which have multiple icustay_ids.  
DROP MATERIALIZED VIEW IF EXISTS echo_icustay CASCADE; 

CREATE MATERIALIZED VIEW echo_icustay AS  

WITH echo_icustay AS (

    SELECT ed.row_id, ed.hadm_id, ed.charttime

    -- icustay 
    , ie.icustay_id
    , ROUND( (CAST(ie.outtime AS DATE) - CAST(ie.intime AS DATE)), 4) AS los_icu
    , DENSE_RANK() OVER (PARTITION BY ie.subject_id ORDER BY ie.intime) AS icustay_seq
    , CASE
        WHEN DENSE_RANK() OVER (PARTITION BY ie.hadm_id ORDER BY ie.intime) = 1 THEN 'Y'
        ELSE 'N' END AS first_icu_stay
    , ie.outtime -- icu outtime 

    -- patient 
    , pat.gender
    , pat.subject_id
    , pat.dod

    -- hospital 
    , adm.admittime
    , adm.dischtime -- hospital discharge time
    , adm.ethnicity
    , age(adm.admittime, pat.dob) AS age
    -- , ROUND( (CAST(adm.admittime AS DATE) - CAST(pat.dob AS DATE))  / 365.242, 4) AS age
    , adm.diagnosis


    -- echos
    , ed.charttime - adm.admittime AS time_to_echo

    FROM icustays ie
    INNER JOIN echodata ed
        ON ie.hadm_id = ed.hadm_id
    INNER JOIN admissions adm
        ON ie.hadm_id = adm.hadm_id
    INNER JOIN patients pat
        ON ie.subject_id = pat.subject_id
), 
        
max_icustay_seq AS (

    SELECT eis.hadm_id
    , MAX(eis.icustay_seq) AS max_icustay_seq
    FROM echo_icustay as eis
    GROUP BY eis.hadm_id
)

SELECT eis.*, mis.max_icustay_seq
    , (( eis.time_to_echo > INTERVAL '-8 hours') AND 
        (eis.time_to_echo < INTERVAL '48 hours')) AS time_filter
    , max_icustay_seq = 1 AS single_stay_filter
    , eis.age > INTERVAL '18 years' AS age_filter
FROM echo_icustay eis
INNER JOIN max_icustay_seq mis
    ON eis.hadm_id = mis.hadm_id
