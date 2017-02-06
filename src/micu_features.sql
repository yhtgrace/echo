DROP MATERIALIZED VIEW IF EXISTS micu_features CASCADE;

CREATE MATERIALIZED VIEW micu_features AS

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
, filter_angus AS ( 
    SELECT DISTINCT ag.hadm_id
        , 1 AS angus_sepsis_flg
    FROM angus_sepsis as ag
    INNER JOIN micu_icustays ic
        ON ag.hadm_id = ic.hadm_id
)
, filters AS (
    SELECT ic.icustay_id
        -- whether or not patient was on vasopressor during icustay
        ,fv.ps_vaso IS NOT NULL as ps_vaso
        -- whether or not patient was on chronic dialysis during hadm
        ,fcd.chronic_dial_flg IS NOT NULL as chronic_dialysis
        -- whether or not patient has sepsis according to the angus definition
        ,fa.angus_sepsis_flg IS NOT NULL as angus_sepsis
        -- age on admission to the icu
        ,age(ic.intime, pt.dob) > INTERVAL '18 years' AS adult
        -- whether or not patient has an echo
        ,fe.echo_flg IS NOT NULL as echo
    FROM micu_icustays ic
    LEFT JOIN filter_vaso fv
        ON ic.icustay_id = fv.icustay_id
    LEFT JOIN filter_chronic_dialysis fcd
        ON ic.hadm_id = fcd.hadm_id
    LEFT JOIN filter_angus fa
        ON ic.hadm_id = fa.hadm_id
    LEFT JOIN filter_echo fe
        ON ic.icustay_id = fe.icustay_id 
    INNER JOIN patients pt
        ON ic.subject_id = pt.subject_id
)

-- calculate other features

-- height in cm
, height as(
    select subject_id, hadm_id, icustay_id
        , avg(  
            case 
                when itemid in (920, 1394, 4187, 3486, 226707)
                    THEN valuenum*2.54 --convert to cm
                else valuenum -- already in cm
            end
        ) as valuenum
    from chartevents
    where itemid in (920, 1394, 4187, 3486, 3485, 4188, 226707)
    AND valuenum IS NOT NULL
    AND valuenum > 0
    AND valuenum < 500
    GROUP BY subject_id, hadm_id, icustay_id
)

-- weight in kg
, weight as(
    select subject_id, hadm_id, icustay_id
        , avg(
            case
                when itemid in (3581, 226512)
                   then valuenum*0.45359237
                when itemid = 3582
                   then valuenum*0.0283495231
                else valuenum
            end
        ) as valuenum
    from chartevents
    where itemid in (762, 763, 3723, 3580, 3581, 3582, 226512)
    AND valuenum IS NOT NULL
    AND valuenum > 0
    GROUP BY subject_id, hadm_id, icustay_id
)

-- collate features

SELECT ic.icustay_id, ic.hadm_id, ic.subject_id

    -- demographics
    ,age(ic.intime,pt.dob)-- age at admission to ICU
    ,pt.gender -- gender
    ,ht.valuenum as height -- height (cm)
    ,wt.valuenum as weight -- weight (kg)
    ,wt.valuenum/power(ht.valuenum/100, 2) as bmi -- bmi
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

    -- labs (first day)
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
    -- true if patient has sepsis according to the angus definition during hospital admission
    ,fs.angus_sepsis AS filter_angus_sepsis
    -- true if patient was > 18 years at time of icustay admission
    ,fs.adult AS filter_adult
    -- true if patient had an echo during that icustay
    ,fs.echo AS filter_echo

    -- ventilation features

    -- fluid features

    -- echo features
    -- echo info (echodata)
    ,ef.ed_chartdate
    ,ef.ed_charttime
    ,ef.ed_quality
    ,ef.ed_indication
    ,ef.ed_bsa
    ,ef.ed_bp
    ,ef.ed_bpsys
    ,ef.ed_bpdias 
    ,ef.ed_hr
    ,ef.ed_test
    ,ef.ed_doppler
    ,ef.ed_contrast

    -- echo annotations
    ,ef.ea_first_careunit
    ,ef.ea_age
    ,ef.ea_age_of_death
    ,ef.ea_days_after_discharge_death
    ,ef.ea_status
    ,ef.ea_tv_pulm_htn
    ,ef.ea_tv_tr
    ,ef.ea_lv_cavity
    ,ef.ea_lv_diastolic
    ,ef.ea_lv_systolic
    ,ef.ea_lv_wall
    ,ef.ea_rv_cavity
    ,ef.ea_rv_diastolic_fluid
    ,ef.ea_rv_systolic
    ,ef.ea_rv_wall

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
LEFT JOIN height ht
    ON ic.icustay_id = ht.icustay_id
LEFT JOIN weight wt
    ON ic.icustay_id = wt.icustay_id
LEFT JOIN echo_features ef
    ON ic.icustay_id = ef.icustay_id



