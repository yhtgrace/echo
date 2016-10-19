DROP MATERIALIZED VIEW IF EXISTS diagnoses CASCADE;

CREATE MATERIALIZED VIEW diagnoses AS

SELECT DISTINCT eis.hadm_id
    ,did.short_title
    ,did.long_title 
    ,di.seq_num
FROM echo_icustay eis
INNER JOIN DIAGNOSES_ICD di
    ON eis.hadm_id = di.hadm_id
INNER JOIN D_ICD_DIAGNOSES did
    ON di.icd9_code = did.icd9_code
