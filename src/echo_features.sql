-- for a clean copy of echo_features, run in order
-- echo_icustay (25512)
-- d_diagnoses_xc_annot (392)
-- d_prescriptions_vaso (49)
-- echo_outpatient (4385)
-- echo_filter_vars (25512)
-- echo_features_labs (25512) 

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
    ,pt.dod > ic.outtime AS survived_icustay -- survived icustay
    ,pt.dod > am.dischtime AS survived_hadm -- survived hospital admission

    -- echo info
    ,ed.chartdate AS echo_chartdate
    ,ed.charttime AS echo_charttime
    ,ed.technicalquality AS echo_quality
    ,ed.bsa AS echo_bsa
    ,ed.bp AS echo_bp
    ,ed.bpsys AS echo_bpsys
    ,ed.bpdias AS echo_bpdias 
    ,ed.hr AS echo_hr

    -- labs
    ,ls.lab_albumin_min, ls.lab_albumin_max
    ,ls.lab_bicarbonate_min, ls.lab_bicarbonate_max
    ,ls.lab_ckmb_min, ls.lab_ckmb_max
    ,ls.lab_creatinine_min, ls.lab_creatinine_max
    ,ls.lab_crp_min, ls.lab_crp_max
    ,ls.lab_egfr_min, ls.lab_egfr_max
    ,ls.lab_hematocrit_min, ls.lab_hematocrit_max
    ,ls.lab_inr_min, ls.lab_inr_max
    ,ls.lab_lactate_min, ls.lab_lactate_max
    ,ls.lab_platelet_min, ls.lab_platelet_max
    ,ls.lab_ntprobnp_min, ls.lab_ntprobnp_max
    ,ls.lab_ph_min, ls.lab_ph_max
    ,ls.lab_tropi_min, ls.lab_tropi_max
    ,ls.lab_tropt_min, ls.lab_tropt_max
    ,ls.lab_wbc_min, ls.lab_wbc_max

    -- filters
    ,ef.ps_vaso -- if patient was on vasopressor during the icustay
    ,ef.diag_xc -- if patient has an excluded diagnosis during the hospital admission
    ,ef.age_filter -- age filter
    ,ef.intime_to_echo -- icustay intime to echo
    ,ef.time_filter -- (icustay intime to echo) between -8 to 48 hours
    ,ef.after_rowid -- row_id of most proximal outpatient echo after this echo
    ,ef.before_rowid -- row_id of most proximal outpatient echo before this echo

    -- ventilation features
    ,vf.noninv_vent
    ,vf.mech_vent

FROM echo_filter_vars ef
INNER JOIN icustays ic
    ON ef.icustay_id = ic.icustay_id
INNER JOIN patients pt
    ON ic.subject_id = pt.subject_id
INNER JOIN admissions am
    ON ef.hadm_id = am.hadm_id
INNER JOIN echodata ed
    ON ef.row_id = ed.row_id
INNER JOIN echo_features_labs ls
    ON ef.row_id = ls.row_id
INNER JOIN ventfeatures vf
    ON ef.row_id = vf.row_id
