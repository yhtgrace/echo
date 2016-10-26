-- annotate number of hospital admissions and icustays for each patient in the database
DROP MATERIALIZED VIEW IF EXISTS num_stays CASCADE;

CREATE MATERIALIZED VIEW num_stays AS

WITH stays AS (

    SELECT ie.subject_id

        , DENSE_RANK() OVER (PARTITION BY ie.subject_id ORDER BY ie.intime) AS icustay_seq
        , DENSE_RANK() OVER (PARTITION BY adm.subject_id ORDER BY adm.admittime) AS adm_seq

    FROM icustays ie
    INNER JOIN admissions adm
        ON ie.hadm_id = adm.hadm_id
) 

SELECT subject_id
    , MAX(icustay_seq)
FROM stays
GROUP BY subject_id
