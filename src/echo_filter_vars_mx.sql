-- Run in order before echo_filter_vars_mx:
-- echo_icustay
-- chronic_dialysis
-- apache from mimic-code
-- load echo annotations
-- fluid_cv_dailyinput
-- fluid_mv_dailyinput
-- fluid_dailybalance
-- echo_first3day_fluid


set search_path to mimiciii;
DROP MATERIALIZED VIEW IF EXISTS echo_filter_vars_mx CASCADE;

CREATE MATERIALIZED VIEW echo_filter_vars_mx AS

WITH
  echo_chronic_dialysis AS (
    SELECT DISTINCT cdial.hadm_id
	, 1 as chronic_dial_flg
    FROM chronic_dialysis cdial
    INNER JOIN echo_icustay ei
        ON cdial.hadm_id = ei.hadm_id
)
, echo_d AS (
SELECT 
        ed.row_id, ed.charttime 
        ,ie.icustay_id, ie.hadm_id, ie.subject_id, ie.intime, ie.outtime
        ,ed.indication, ed.height, ed.weight, ed.bsa, ed.bp, ed.bpsys, ed.bpdias, ed.hr, ed.test, ed.doppler, ed.contrast, ed.technicalquality
    FROM echodata ed
    INNER JOIN icustays ie
        ON ie.hadm_id = ed.hadm_id
        WHERE (ed.charttime > (ie.intime - INTERVAL '8 hours')) AND (ed.charttime < ie.outtime)
)    
-- compute new variables
, echo_ext AS (
    SELECT ei.*
        -- chronic dialysis flag
        ,cdial.chronic_dial_flg IS NOT NULL as chronic_dialysis_flg
	-- echo annotations
        ,eann.age as eage, eann.gender as egender, eann.first_careunit as ecareunit, eann.age_of_death as eage_of_death
        ,eann.days_after_discharge_death as edays_after_discharge_death, eann.status as inoutpatient
        ,eann.tv_pulm_htn, eann.tv_tr, eann.lv_cavity, eann.lv_diastolic, eann.lv_systolic, eann.lv_wall, eann.rv_cavity, eann.rv_diastolic_fluid, 
       eann.rv_systolic, eann.rv_wall
        -- apache score
        ,ap.apsiii, apsiii_prob, creatinine_score as apsiii_creatinine_score
        -- elixhauser commorbidities
        ,elix.congestive_heart_failure, elix.cardiac_arrhythmias, elix.valvular_disease, elix.pulmonary_circulation 
        ,elix.peripheral_vascular, elix.hypertension, elix.paralysis, elix.other_neurological, elix.chronic_pulmonary 
        ,elix.diabetes_uncomplicated, elix.diabetes_complicated, elix.hypothyroidism, elix.renal_failure, elix.liver_disease 
        ,elix.peptic_ulcer, elix.aids, elix.lymphoma, elix.metastatic_cancer, elix.solid_tumor, elix.rheumatoid_arthritis 
        ,elix.coagulopathy, elix.obesity, elix.weight_loss, elix.fluid_electrolyte, elix.blood_loss_anemia, elix.deficiency_anemias 
        ,elix.alcohol_abuse, elix.drug_abuse, elix.psychoses, elix.depression
        ---- echo data
        ,ed.indication, ed.height, ed.weight, ed.bsa, ed.bp, ed.bpsys, ed.bpdias, ed.hr, ed.test, ed.doppler, ed.contrast, ed.technicalquality
	---- fluid data
	--,fl.*
	---- ventilation
	,vf.mechvent as mechvent_flg
    FROM echo_icustay ei
    LEFT JOIN echo_chronic_dialysis cdial        -- added by Minnan
	ON ei.hadm_id = cdial.hadm_id
    LEFT JOIN echo_annotations_unique eann		-- added by Minnan
        ON eann.icustay_id = ei.icustay_id and ei.charttime = eann.new_time    
    LEFT JOIN apsiii ap
        ON ei.icustay_id = ap.icustay_id
    LEFT JOIN elixhauser_ahrq elix
        ON ei.hadm_id = elix.hadm_id
    LEFT JOIN echo_d ed
        ON ei.row_id = ed.row_id
    --LEFT JOIN echo_first3day_fluid fl
     --   ON ei.row_id = fl.row_id
    LEFT JOIN ventfirstday vf
        ON ei.icustay_id = vf.icustay_id
    INNER JOIN icustays ic
        ON ei.icustay_id = ic.icustay_id
    INNER JOIN patients pt
        ON ic.subject_id = pt.subject_id
)
-- add filters
-- TODO: implement filter to remove echos if more than 3 echos in 1 icustay?
SELECT * FROM echo_ext

