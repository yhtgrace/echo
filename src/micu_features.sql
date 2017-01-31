DROP MATERIALIZED VIEW IF EXISTS micu_features CASCADE;

CREATE MATERIALIZED VIEW micu_features AS

-- only look at icustays with micu as first or last careunit

WITH micu_icustays AS (
    SELECT * 
    FROM icustays 
    WHERE (first_careunit = 'MICU') OR (last_careunit = 'MICU')
)

-- calculate flags for filtering

, filter_vaso AS (
    SELECT DISTINCT ps.icustay_id
        , 1 AS ps_vaso
    FROM prescriptions ps
    INNER JOIN micu_icustays ic
        ON ic.icustay_id = ps.icustay_id 
    INNER JOIN d_prescriptions_vaso dpv
        ON ( ps.drug                 IS NOT DISTINCT FROM dpv.drug 
         AND ps.drug_name_poe        IS NOT DISTINCT FROM dpv.drug_name_poe
         AND ps.drug_name_generic    IS NOT DISTINCT FROM dpv.drug_name_generic
         AND ps.route                IS NOT DISTINCT FROM dpv.route )
)
, filter_chronic_dialysis AS (
    SELECT DISTINCT cd.hadm_id
        , 1 AS chronic_dial_flg
    FROM chronic_dialysis cd
    INNER JOIN micu_icustays ic
        ON cd.hadm_id = ic.hadm_id
)
, filter_echo AS (
    SELECT DISTINCT ei.icustay_id
        , 1 AS echo_flg
    FROM echo_icustay ei
    INNER JOIN micu_icustays ic
        ON ic.icustay_id = ei.icustay_id
)
, filters AS (
    SELECT ic.icustay_id
        -- whether or not patient was on vasopressor during icustay
        ,fv.ps_vaso IS NOT NULL as ps_vaso
        -- whether or not patient was on chronic dialysis during hadm
        ,fcd.chronic_dial_flg IS NOT NULL as chronic_dialysis
        -- age on admission to the icu
        ,age(ic.intime, pt.dob) > INTERVAL '18 years' AS adult
        -- whether or not patient has an echo
        ,fe.echo_flg IS NOT NULL as echo
    FROM micu_icustays ic
    LEFT JOIN filter_vaso fv
        ON ic.icustay_id = fv.icustay_id
    LEFT JOIN filter_chronic_dialysis fcd
        ON ic.hadm_id = fcd.hadm_id
    LEFT JOIN filter_echo fe
        ON ic.icustay_id = fe.icustay_id 
    INNER JOIN patients pt
        ON ic.subject_id = pt.subject_id
)

-- collate features

SELECT ic.icustay_id, ic.hadm_id, ic.subject_id

    -- demographics
    ,age(ic.intime,pt.dob)-- age at admission to ICU
    ,pt.gender -- gender
    -- height
    -- weight
    -- bmi
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

    -- labs
    ,ls.lab_albumin
    ,ls.lab_bicarbonate
    ,ls.lab_ckmb
    ,ls.lab_creatinine
    ,ls.lab_crp
    ,ls.lab_egfr
    ,ls.lab_hematocrit
    ,ls.lab_inr
    ,ls.lab_lactate
    ,ls.lab_platelet
    ,ls.lab_ntprobnp
    ,ls.lab_ph
    ,ls.lab_tropi
    ,ls.lab_tropt
    ,ls.lab_wbc

    -- filters
    -- true if patient was on vasopressor during icustay
    ,fs.ps_vaso AS filter_vaso 
    -- true if patient was on chronic dialysis during hospital admission
    ,fs.chronic_dialysis AS filter_chronic_dialysis 
    -- true if patient was > 18 years at time of icustay admission
    ,fs.adult AS filter_adult
    -- true if patient had an echo during that icustay
    ,fs.echo AS filter_echo

    -- ventilation features

    -- fluid features

FROM micu_icustays ic
INNER JOIN patients pt
    ON ic.subject_id = pt.subject_id
INNER JOIN admissions am
    ON ic.hadm_id = am.hadm_id
INNER JOIN filters fs
    ON ic.icustay_id = fs.icustay_id
LEFT JOIN elixhauser_ahrq ex
    ON ic.hadm_id = ex.hadm_id
LEFT JOIN apsiii ap
    ON ic.icustay_id = ap.icustay_id
LEFT JOIN labsfirstday_ ls
    ON ic.icustay_id = ls.icustay_id 
