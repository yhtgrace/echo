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
    
-- compute new variables
, echo_ext AS (
    SELECT ei.*
        -- chronic dialysis flag
        ,cdial.chronic_dial_flg IS NOT NULL as chronic_dialysis_flg
	-- echo annotations
        ,eann.tv_pulm_htn, eann.tv_tr, eann.lv_cavity, eann.lv_diastolic, eann.lv_systolic, eann.lv_wall, eann.rv_cavity, eann.rv_diastolic_fluid, 
       eann.rv_systolic, eann.rv_wall
        -- apache score
        ,ap.apsiii, apsiii_prob, creatinine_score
        -- elixhauser commorbidities
        ,elix.congestive_heart_failure, elix.cardiac_arrhythmias,elix.valvular_disease, elix.pulmonary_circulation, 
        elix.peripheral_vascular, elix.hypertension, elix.paralysis, elix.other_neurological, elix.chronic_pulmonary, 
       elix.diabetes_uncomplicated, elix.diabetes_complicated, elix.hypothyroidism, elix.renal_failure, elix.liver_disease, 
       elix.peptic_ulcer, elix.aids, elix.lymphoma, elix.metastatic_cancer, elix.solid_tumor, elix.rheumatoid_arthritis, 
       elix.coagulopathy, elix.obesity, elix.weight_loss, elix.fluid_electrolyte, elix.blood_loss_anemia, elix.deficiency_anemias, 
       elix.alcohol_abuse, elix.drug_abuse, elix.psychoses, elix.depression
    FROM echo_icustay ei
    LEFT JOIN echo_chronic_dialysis cdial        -- added by Minnan
	ON ei.hadm_id = cdial.hadm_id
    LEFT JOIN echo_annotations_unique eann		-- added by Minnan
        ON eann.icustay_id = ei.icustay_id and ei.charttime = eann.new_time    
    LEFT JOIN apsiii ap
        ON ei.icustay_id = ap.icustay_id
    LEFT JOIN elixhauser_ahrq elix
        ON ei.hadm_id = elix.hadm_id
    LEFT JOIN elixhauser_ahrq
    INNER JOIN icustays ic
        ON ei.icustay_id = ic.icustay_id
    INNER JOIN patients pt
        ON ic.subject_id = pt.subject_id
)
-- add filters
-- TODO: implement filter to remove echos if more than 3 echos in 1 icustay
SELECT * FROM echo_ext

