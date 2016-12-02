DROP MATERIALIZED VIEW IF EXISTS echo_features CASCADE;

CREATE MATERIALIZED VIEW echo_features AS

SELECT ef.row_id, ef.icustay_id, ef.hadm_id, ef.subject_id 

    -- demographics
    ,ef.age_at_intime -- age at admission to ICU
    ,pt.gender -- gender
    ,ed.height -- height from echo chart, probably in inches
    ,ed.weight -- weight from echo chart, probably in lbs
    ,703 * ed.weight / (ed.height * ed.height) AS bmi -- bmi, (lb * 703)/(in * in)
                                                      -- see http://www.calcbmi.com/
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

    -- echo info
    ,ed.chartdate AS echo_chartdate
    ,ed.charttime AS echo_charttime
    ,ed.technicalquality AS echo_quality
    ,ed.bsa AS echo_bsa
    ,ed.bp AS echo_bp
    ,ed.bpsys AS echo_bpsys
    ,ed.bpdias AS echo_bpdias 
    ,ed.hr AS echo_hr

FROM echo_filter_vars ef
INNER JOIN icustays ic
    ON ef.icustay_id = ic.icustay_id
INNER JOIN patients pt
    ON ic.subject_id = pt.subject_id
INNER JOIN admissions am
    ON ef.hadm_id = am.hadm_id
INNER JOIN echodata ed
    ON ef.row_id = ed.row_id
