DROP MATERIALIZED VIEW IF EXISTS echo_features CASCADE;

CREATE MATERIALIZED VIEW echo_features AS

SELECT ef.row_id, ef.icustay_id, ef.hadm_id, ef.subject_id 

    -- demographics
    ,ef.age_at_intime -- age at admission to ICU
    ,pt.gender -- gender
    ,ed.height -- height from echo chart
    ,ed.weight -- weight from echo chart
    -- bmi
    ,am.ethnicity -- race
    ,am.insurance -- insurance

    -- timeline
    ,am.admittime -- hospital admission date/time
    ,am.dischtime -- hospital discharge date/time
    ,ic.intime -- icustay in date/time
    ,ic.outtime -- icustay out date/time
   
    -- outcomes
    ,pt.dod -- date of death
    ,pt.dod > ic.outtime AS survived_icustay-- survived icustay
    ,pt.dod > am.dischtime AS survived_hadm-- survived hospital admission

FROM echo_filtered ef
INNER JOIN icustays ic
    ON ef.icustay_id = ic.icustay_id
INNER JOIN patients pt
    ON ic.subject_id = pt.subject_id
INNER JOIN admissions am
    ON ef.hadm_id = am.hadm_id
INNER JOIN echodata ed
    ON ef.row_id = ed.row_id
