-- for a clean copy of echo_features, run in order
-- echo_icustay (25512)
-- d_diagnoses_xc_annot (392)
-- d_prescriptions_vaso (49)
-- echo_outpatient (4385)
-- echo_filter_vars (25512)
-- echo_features_labs (25512) 

DROP MATERIALIZED VIEW IF EXISTS echo_features CASCADE;

CREATE MATERIALIZED VIEW echo_features AS

WITH fluids AS (
    SELECT icustay_id, chartdate
        ,avg(daily_input_ml) as daily_input_ml
        ,avg(daily_output_ml) as daily_output_ml
        ,avg(daily_balance_ml) as daily_balance_ml
    FROM fluid_dailybalance 
    GROUP BY icustay_id, chartdate
)
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

    -- comorbidities 
    ,ex.congestive_heart_failure AS ex_congestive_heart_failure
    ,ex.cardiac_arrhythmias AS ex_cardiac_aarrhythmias
    ,ex.valvular_disease AS ex_valvular_disease
    ,ex.pulmonary_circulation AS ex_pulmonary_circulation
    ,ex.peripheral_vascular AS ex_peripheral_vascular
    ,ex.hypertension AS ex_hypertension
    ,ex.paralysis AS ex_paralysis
    ,ex.other_neurological AS ex_other_neurological
    ,ex.chronic_pulmonary AS ex_chronic_pulmonary
    ,ex.diabetes_uncomplicated AS ex_diabetes_uncomplicated
    ,ex.diabetes_complicated AS ex_diabetes_complicated
    ,ex.hypothyroidism AS ex_hypothyroidism
    ,ex.renal_failure AS ex_renal_failure
    ,ex.liver_disease AS ex_liver_disease
    ,ex.peptic_ulcer AS ex_peptic_ulcer
    ,ex.aids AS ex_aids
    ,ex.lymphoma AS ex_lymphoma
    ,ex.metastatic_cancer AS ex_metastatic_cancer
    ,ex.solid_tumor AS ex_solid_tumor
    ,ex.rheumatoid_arthritis AS ex_rheumatoid_arthritis
    ,ex.coagulopathy AS ex_coagulopathy
    ,ex.obesity AS ex_obesity
    ,ex.weight_loss AS ex_weight_loss
    ,ex.fluid_electrolyte AS ex_fluid_electrolyte
    ,ex.blood_loss_anemia AS ex_blood_loss_anemia
    ,ex.deficiency_anemias AS ex_deficiency_anemias
    ,ex.alcohol_abuse AS ex_alcohol_abuse
    ,ex.drug_abuse AS ex_drug_abuse
    ,ex.psychoses AS ex_psychoses
    ,ex.depression AS ex_depression

    -- apache scores
    ,ap.apsiii
    ,ap.apsiii_prob
    ,ap.creatinine_score AS apsiii_creatinine_score
    
    -- timeline
    ,am.admittime -- hospital admission date/time
    ,am.dischtime -- hospital discharge date/time
    ,ic.intime -- icustay in date/time
    ,ic.outtime -- icustay out date/time
   
    -- outcomes
    ,pt.dod -- date of death
    ,pt.dod > ic.outtime AS survived_icustay -- survived icustay
    ,pt.dod > am.dischtime AS survived_hadm -- survived hospital admission

    -- echo info (echodata)
    ,ed.chartdate AS ed_chartdate
    ,ed.charttime AS ed_charttime
    ,ed.technicalquality AS ed_quality
    ,ed.indication AS ed_indication
    ,ed.bsa AS ed_bsa
    ,ed.bp AS ed_bp
    ,ed.bpsys AS ed_bpsys
    ,ed.bpdias AS ed_bpdias 
    ,ed.hr AS ed_hr
    ,ed.test AS ed_test
    ,ed.doppler AS ed_doppler
    ,ed.contrast AS ed_contrast

    -- echo annotations
    ,ea.first_careunit AS ea_first_careunit
    ,ea.age AS ea_age
    ,ea.age_of_death AS ea_age_of_death
    ,ea.days_after_discharge_death AS ea_days_after_discharge_death
    ,ea.status AS ea_status
    ,ea.tv_pulm_htn AS ea_tv_pulm_htn
    ,ea.tv_tr AS ea_tv_tr
    ,ea.lv_cavity AS ea_lv_cavity
    ,ea.lv_diastolic AS ea_lv_diastolic
    ,ea.lv_systolic AS ea_lv_systolic
    ,ea.lv_wall AS ea_lv_wall
    ,ea.rv_cavity AS ea_rv_cavity
    ,ea.rv_diastolic_fluid AS ea_rv_diastolic_fluid
    ,ea.rv_systolic AS ea_rv_systolic
    ,ea.rv_wall AS ea_rv_wall

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

    -- fluid features
    ,fd1.daily_input_ml AS fluid_daily_input_ml_1
    ,fd1.daily_output_ml AS fluid_daily_output_ml_1
    ,fd1.daily_balance_ml AS fluid_daily_balance_ml_1
    ,fd1.chartdate AS fluid_chartdate_1
    ,fd2.daily_input_ml AS fluid_daily_input_ml_2
    ,fd2.daily_output_ml AS fluid_daily_output_ml_2
    ,fd2.daily_balance_ml AS fluid_daily_balance_ml_2
    ,fd2.chartdate AS fluid_chartdate_2
    ,fd3.daily_input_ml AS fluid_daily_input_ml_3
    ,fd3.daily_output_ml AS fluid_daily_output_ml_3
    ,fd3.daily_balance_ml AS fluid_daily_balance_ml_3
    ,fd3.chartdate AS fluid_chartdate_3

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
LEFT JOIN elixhauser_ahrq ex
    ON ef.hadm_id = ex.hadm_id
LEFT JOIN apsiii ap
    ON ef.icustay_id = ap.icustay_id
LEFT JOIN echo_annotations_unique ea
    ON ef.icustay_id = ea.icustay_id AND 
    ef.charttime IS NOT DISTINCT FROM ea.new_time
LEFT JOIN fluids fd1
    ON ef.icustay_id = fd1.icustay_id AND 
    (CAST(ef.charttime AS DATE)) IS NOT DISTINCT FROM fd1.chartdate 
LEFT JOIN fluids fd2
    ON ef.icustay_id = fd2.icustay_id AND 
    (CAST(ef.charttime AS DATE) + interval '1 day') IS NOT DISTINCT FROM fd2.chartdate 
LEFT JOIN fluids fd3
    ON ef.icustay_id = fd3.icustay_id AND 
    (CAST(ef.charttime AS DATE) + interval '2 day') IS NOT DISTINCT FROM fd3.chartdate 
