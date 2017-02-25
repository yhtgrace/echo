DROP MATERIALIZED VIEW IF EXISTS icu_features CASCADE;

CREATE MATERIALIZED VIEW icu_features AS

-- calculate flags for filtering

WITH filter_vaso AS (
    SELECT DISTINCT ps.icustay_id
        , 1 AS ps_vaso
    FROM prescriptions ps
    INNER JOIN icustays ic
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
    INNER JOIN icustays ic
        ON cd.hadm_id = ic.hadm_id
)
, filter_angus AS ( 
    SELECT DISTINCT ag.hadm_id
        , ag.angus AS angus_sepsis_flg
    FROM angus_sepsis as ag
    INNER JOIN icustays ic
        ON ag.hadm_id = ic.hadm_id
)
, filters AS (
    SELECT ic.icustay_id
        -- whether or not patient was on vasopressor during icustay
        ,fv.ps_vaso IS NOT NULL as ps_vaso
        -- whether or not patient was on chronic dialysis during hadm
        ,fcd.chronic_dial_flg IS NOT NULL as chronic_dialysis
        -- whether or not patient has sepsis according to the angus definition
        ,fa.angus_sepsis_flg as angus_sepsis
        -- whether or not patient was flagged as having a hard cardiogenic filter
        ,cf.any_flg AS hard_cardiogenic
        -- age on admission to the icu
        ,age(ic.intime, pt.dob) > INTERVAL '18 years' AS adult
    FROM icustays ic
    LEFT JOIN filter_vaso fv
        ON ic.icustay_id = fv.icustay_id
    LEFT JOIN filter_chronic_dialysis fcd
        ON ic.hadm_id = fcd.hadm_id
    LEFT JOIN filter_angus fa
        ON ic.hadm_id = fa.hadm_id
    LEFT JOIN hard_cardiogenic_filters cf
        ON ic.icustay_id = cf.icustay_id
    INNER JOIN patients pt
        ON ic.subject_id = pt.subject_id
)

-- calculate new features

-- height in cm
, height as (
    select subject_id
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
    GROUP BY subject_id
)

-- weight in kg
, weight as (
    select icustay_id
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
    GROUP BY icustay_id
)

-- get echo features
, icustay_ed AS (
    SELECT ed.*, ic.icustay_id
        , DENSE_RANK() OVER (PARTITION BY ic.icustay_id ORDER BY ed.charttime) AS first_echo
        , CASE
            WHEN technicalquality = 'Adequate' then 2
            WHEN technicalquality = 'Suboptimal' then 1
            WHEN technicalquality = 'Good' then 3
            ELSE 0
          END AS technicalquality_
    FROM echodata ed
    INNER JOIN icustays ic
        ON ic.hadm_id = ed.hadm_id
        WHERE (ed.charttime > (ic.intime - INTERVAL '8 hours')) AND
              (ed.charttime < ic.outtime)
)
-- get first echo for each icustay
-- if there are multiple echos at the first time-point
-- get the one with the best quality 
, icustay_first_ed AS (
    SELECT DISTINCT ON (icustay_id) * 
    FROM icustay_ed
    WHERE first_echo = 1
    ORDER BY icustay_id, technicalquality_ DESC
)
SELECT ic.icustay_id, ic.hadm_id, ic.subject_id

    -- demographics
    ,age(ic.intime, pt.dob)-- age at admission to ICU
    ,pt.gender -- gender
    ,ht.valuenum as height -- height (cm)
    ,wt.valuenum as weight -- weight (kg)
    ,wt.valuenum/power(ht.valuenum/100, 2) as bmi -- bmi
    ,am.ethnicity -- race
    ,am.insurance -- insurance
    ,ic.dbsource as dbsource

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
    
    -- secondary outcomes
    ,so.creatinine_last
    ,so.creatinine_max
    ,so.lactate_last
    ,so.lactate_max

    -- labs on first day of icustay
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
    -- true if patient flagged by one of the hard cardiogenic filters
    ,fs.hard_cardiogenic AS filter_hard_cardiogenic
    -- true if patient was > 18 years at time of icustay admission
    ,fs.adult AS filter_adult
    -- true if patient had an echo during that icustay
    ,ed.charttime IS NOT NULL AS filter_echo
    -- true if first careunit or last careunit was micu
    -- ,(ic.first_careunit = 'MICU') OR (ic.last_careunit = 'MICU') AS filter_micu

    -- service type
    ,ic.first_careunit as ic_first_careunit
    ,ic.last_careunit as ic_last_careunit
    ,case
        when st.micu = 1 then 1
        when (st.micu IS NULL) AND ((ic.first_careunit = 'MICU') OR 
            (ic.last_careunit = 'MICU')) then 1
        else 0 end AS st_micu
    ,case 
        when st.sicu = 1 then 1
        when (st.sicu IS NULL) AND ((ic.first_careunit in ('SICU', 'TSICU')) OR
            (ic.last_careunit in ('SICU', 'TSICU'))) then 1
        else 0 end AS st_sicu
    ,st.nsicu AS st_nsicu

    -- ventilation features
    ,vf.first_day_vent as vf_first_day_vent
    ,vf.duration as vf_duration

    -- fluid features
    ,fb.day1_input_ml as fb_day1_input_ml
    ,fb.day1_output_ml as fb_day1_output_ml
    ,fb.day1_balance_ml as fb_day1_balance_ml 
    ,fb.day2_input_ml as fb_day2_input_ml
    ,fb.day2_output_ml as fb_day2_output_ml
    ,fb.day2_balance_ml as fb_day2_balance_ml
    ,fb.day3_input_ml as fb_day3_input_ml
    ,fb.day3_output_ml as fb_day3_output_ml
    ,fb.day3_balance_ml as fb_day3_balance_ml

    -- echo features
    -- first echo of each icustay
    -- if multiple echos at first time-point, sort by quality and take best

    -- echo info (echodata)
    ,ed.chartdate as ed_chartdate
    ,ed.charttime as ed_charttime
    ,ed.technicalquality as ed_quality
    ,ed.indication as ed_indication
    ,ed.bsa as ed_bsa
    ,ed.bp as ed_bp
    ,ed.bpsys as ed_bpsys
    ,ed.bpdias  as ed_bpdias 
    ,ed.hr as ed_hr
    ,ed.test as ed_test
    ,ed.doppler as ed_doppler
    ,ed.contrast as ed_contrast

    -- echo annotations
    ,ea.age as ea_age
    ,ea.age_of_death as ea_age_of_death
    ,ea.days_after_discharge_death as ea_days_after_discharge_death
    ,ea.status as ea_status
    ,ea.tv_pulm_htn as ea_tv_pulm_htn
    ,ea.tv_tr as ea_tv_tr
    ,ea.lv_cavity as ea_lv_cavity
    ,ea.lv_diastolic as ea_lv_diastolic
    ,ea.lv_systolic as ea_lv_systolic
    ,ea.lv_wall as ea_lv_wall
    ,ea.rv_cavity as ea_rv_cavity
    ,ea.rv_diastolic_fluid as ea_rv_diastolic_fluid
    ,ea.rv_systolic as ea_rv_systolic
    ,ea.rv_wall as ea_rv_wall

FROM icustays ic
INNER JOIN patients pt
    ON ic.subject_id = pt.subject_id
INNER JOIN admissions am
    ON ic.hadm_id = am.hadm_id
LEFT JOIN height ht
    ON ic.subject_id = ht.subject_id
LEFT JOIN weight wt
    ON ic.icustay_id = wt.icustay_id
LEFT JOIN filters fs
    ON ic.icustay_id = fs.icustay_id
LEFT JOIN elixhauser_ahrq ex
    ON ic.hadm_id = ex.hadm_id
LEFT JOIN apsiii ap
    ON ic.icustay_id = ap.icustay_id
LEFT JOIN labsfirstday_ ls
    ON ic.icustay_id = ls.icustay_id 
LEFT JOIN secondary_outcomes so
    ON ic.icustay_id = so.icustay_id
LEFT JOIN icustay_first_ed ed
    ON ic.icustay_id = ed.icustay_id
LEFT JOIN echo_annotations_unique ea
    ON ic.icustay_id = ea.icustay_id AND
    ed.charttime IS NOT DISTINCT FROM ea.new_time
LEFT JOIN service_type_MICU_SICU_NSICU st
    ON ic.icustay_id = st.icustay_id
INNER JOIN fluid_balance_day123 fb
    ON ic.icustay_id = fb.icustay_id
LEFT JOIN ventfeatures vf
    ON ic.icustay_id = vf.icustay_id
