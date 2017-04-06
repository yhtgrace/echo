set search_path to mimiciii;

DROP MATERIALIZED VIEW IF EXISTS icu_features CASCADE;

CREATE MATERIALIZED VIEW icu_features AS

-- flags for filtering

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

-- echo features

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
-- get best echo for each (hadm_id, echo_annotations)
-- coincidentally this ensures that the echo is unique per icustay_id
, echo_annotations_qual AS (
    SELECT * 
        , (CASE WHEN tv_pulm_htn        IS NULL THEN 1 ELSE 0 END) + 
          (CASE WHEN tv_regurgitation   IS NULL THEN 1 ELSE 0 END) +
          (CASE WHEN tv_stenosis        IS NULL THEN 1 ELSE 0 END) +
          (CASE WHEN lv_cavity          IS NULL THEN 1 ELSE 0 END) +
          (CASE WHEN lv_diastolic       IS NULL THEN 1 ELSE 0 END) +
          (CASE WHEN lv_systolic        IS NULL THEN 1 ELSE 0 END) +
          (CASE WHEN lv_wall            IS NULL THEN 1 ELSE 0 END) + 
          (CASE WHEN rv_cavity          IS NULL THEN 1 ELSE 0 END) + 
          (CASE WHEN rv_volume_overload IS NULL THEN 1 ELSE 0 END) + 
          (CASE WHEN rv_systolic        IS NULL THEN 1 ELSE 0 END) +
          (CASE WHEN rv_wall            IS NULL THEN 1 ELSE 0 END) +
          (CASE WHEN av_regurgitation   IS NULL THEN 1 ELSE 0 END) +
          (CASE WHEN av_stenosis        IS NULL THEN 1 ELSE 0 END) +
          (CASE WHEN mv_regurgitation   IS NULL THEN 1 ELSE 0 END) +
          (CASE WHEN mv_stenosis        IS NULL THEN 1 ELSE 0 END) +
          (CASE WHEN la_cavity          IS NULL THEN 1 ELSE 0 END) +
          (CASE WHEN ra_dilated         IS NULL THEN 1 ELSE 0 END) +
          (CASE WHEN ra_pressure        IS NULL THEN 1 ELSE 0 END) AS num_not_null
    FROM echo_annotations_unique
)
, echo_annotations_unique_ AS (
    SELECT DISTINCT ON (hadm_id, new_time) * 
    FROM echo_annotations_qual 
    ORDER BY hadm_id, new_time, num_not_null DESC
)

-- height and weight

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

, icu_features_ as (
    SELECT ic.icustay_id, ic.hadm_id, ic.subject_id

        -- demographics
        ,age(ic.intime, pt.dob)-- age at admission to ICU
        ,pt.gender -- gender
        ,case when ht.valuenum IS NOT NULL then ht.valuenum else ea.height*2.54 end 
            as height -- height(cm) 
            ,case when wt.valuenum IS NOT NULL then wt.valuenum else ea.weight*0.45359237 end 
            as weight -- weight (kg)
        ,am.ethnicity -- race
        ,am.insurance -- insurance
        --,ic.dbsource as dbsource
        
        -- filters
        -- true if patient was on vasopressor during icustay
        ,fs.ps_vaso AS filter_vaso 
        -- true if patient was on chronic dialysis during hospital admission
        ,fs.chronic_dialysis AS filter_chronic_dialysis
        -- true if patient has sepsis according to the angus definition during hospital admission
        ,fs.angus_sepsis = 1 AS filter_angus_sepsis
        -- true if patient flagged by one of the hard cardiogenic filters
        ,fs.hard_cardiogenic AS filter_hard_cardiogenic
        -- true if patient was > 18 years at time of icustay admission
        ,fs.adult AS filter_adult
        -- true if patient had an echo during that icustay
        ,ed.charttime IS NOT NULL AS filter_echo
        
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
        ,ea.hadm_id as ea_hadm_id
        ,ea.new_time as ea_new_time
        ,ea.key as ea_key
        ,ea.height as ea_height
        ,ea.weight as ea_weight
        ,ea.sys as ea_sys
        ,ea.diastolic as ea_diastolic
        ,ea.hr as ea_hr
        ,ea.tv_pulm_htn as ea_tv_pulm_htn
        ,ea.tv_regurgitation as ea_tv_regurgitation
        ,ea.tv_stenosis as ea_tv_stenosis
        ,ea.lv_cavity as ea_lv_cavity
        ,ea.lv_diastolic as ea_lv_diastolic
        ,ea.lv_systolic as ea_lv_systolic
        ,ea.lv_wall as ea_lv_wall
        ,ea.rv_cavity as ea_rv_cavity
        ,ea.rv_volume_overload as ea_rv_volume_overload
        ,ea.rv_systolic as ea_rv_systolic
        ,ea.rv_wall as ea_rv_wall
        ,ea.av_regurgitation as ea_av_regurgitation
        ,ea.av_stenosis as ea_av_stenosis
        ,ea.mv_regurgitation as ea_mv_regurgitation
        ,ea.mv_stenosis as ea_mv_stenosis
        ,ea.la_cavity as ea_la_cavity
        ,ea.ra_dilated as ea_ra_dilated
        ,ea.ra_pressure as ea_ra_pressure

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
        ,ic.intime    -- icustay in date/time
        ,ic.outtime   -- icustay out date/time

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
        
        -- service type
        ,ic.first_careunit as ic_first_careunit
        ,ic.last_careunit as ic_last_careunit
        ,case
            when st.micu = 1 then True
            when (st.micu IS NULL) AND ((ic.first_careunit = 'MICU') OR 
                (ic.last_careunit = 'MICU')) then True
            else False end AS st_micu
        ,case 
            when st.sicu = 1 then True
            when (st.sicu IS NULL) AND ((ic.first_careunit in ('SICU', 'TSICU')) OR
                (ic.last_careunit in ('SICU', 'TSICU'))) then True
            else False end AS st_sicu
        ,case when st.nsicu = 1 then True else False end AS st_nsicu
        ,st.carevue = 1 OR dbsource = 'carevue' AS db_carevue
        ,st.metavision = 1 OR dbsource = 'metavision' AS db_metavision

        -- ventilation features
        ,vf.first_day_vent as vf_first_day_vent
        ,vf.duration as vf_duration

        -- fluid features
        ,fb.day1_input_ml as fb_day1_input_ml
        ,fb.day1_output_ml as fb_day1_output_ml
        ,fb.day1_balance_ml as fb_day1_balance_ml
        ,fb.day1_balance_truncated as fb_day1_balance_truncated
        ,fb.day2_input_ml as fb_day2_input_ml
        ,fb.day2_output_ml as fb_day2_output_ml
        ,fb.day2_balance_ml as fb_day2_balance_ml
        ,fb.day2_balance_truncated as fb_day2_balance_truncated
        ,fb.day3_input_ml as fb_day3_input_ml
        ,fb.day3_output_ml as fb_day3_output_ml
        ,fb.day3_balance_ml as fb_day3_balance_ml
        ,fb.day3_balance_truncated as fb_day3_balance_truncated
        ,fb.balance_truncated as fb_balance_truncated

        -- fluid preadmission
        ,fp.inputpreadm as fp_preadmission_input
        ,fp.outputpreadm as fp_preadmission_output

        -- procedures features
        ,pc.arterialline as pc_arterialline
        ,pc.cvc as pc_cvc
        ,pc.dialysis as pc_dialysis
        ,pc.iabp as pc_iabp
        ,pc.impella as pc_impella
        ,pc.pac as pc_pac
        ,pc.port as pc_port
        ,pc.toexclude as pc_toexclude
        ,pc.bronch as pc_bronch
        ,pc.cath as pc_cath
        ,pc.echo as pc_echo
        ,pc.pressor as pc_pressor
        ,pc.rhc as pc_rhc
        ,pc.thora as pc_thora
        ,pc.vent as pc_vent

    FROM icustays ic
    INNER JOIN patients pt
        ON ic.subject_id = pt.subject_id 
    INNER JOIN admissions am
        ON ic.hadm_id = am.hadm_id
    LEFT JOIN filters fs
        ON ic.icustay_id = fs.icustay_id
    LEFT JOIN icustay_first_ed ed
        ON ic.icustay_id = ed.icustay_id
    LEFT JOIN echo_annotations_unique_ ea
        ON ic.hadm_id = ea.hadm_id AND
        ed.charttime IS NOT DISTINCT FROM ea.new_time
    LEFT JOIN elixhauser_ahrq ex
        ON ic.hadm_id = ex.hadm_id
    LEFT JOIN apsiii ap
        ON ic.icustay_id = ap.icustay_id
    LEFT JOIN secondary_outcomes so
        ON ic.icustay_id = so.icustay_id
    LEFT JOIN labsfirstday_ ls
        ON ic.icustay_id = ls.icustay_id 
    LEFT JOIN service_type_MICU_SICU_NSICU st
        ON ic.icustay_id = st.icustay_id
    LEFT JOIN ventfeatures vf
        ON ic.icustay_id = vf.icustay_id
    LEFT JOIN height ht
        ON ic.subject_id = ht.subject_id
    LEFT JOIN weight wt
        ON ic.icustay_id = wt.icustay_id
    LEFT JOIN procedures pc
        ON ic.icustay_id = pc.icustay_id
    LEFT JOIN fluid_balance_day123 fb
        ON ic.icustay_id = fb.icustay_id
    LEFT JOIN fluid_preadmission fp
        ON ic.icustay_id = fp.icustay_id
)

, icu_features_filtered as (
    SELECT *
        ,1 as passed_filters
    FROM icu_features_
    WHERE 
        ((filter_vaso = True) OR (filter_angus_sepsis = True)) AND 
        (filter_hard_cardiogenic = False) AND
        (filter_chronic_dialysis = False) AND 
        (filter_adult = True) AND
        ((st_micu = True) OR (st_sicu = True) OR (st_nsicu = True)) 
)

, icu_features_unique as (
    SELECT DISTINCT ON (subject_id) subject_id, icustay_id, intime, filter_echo
        ,1 as use_record
    FROM icu_features_filtered
    ORDER BY subject_id, icustay_id, filter_echo DESC, intime DESC 
)

--SELECT * FROM icu_features_filtered
SELECT ifs.*
    ,icf.passed_filters as passed_filters
    ,icu.use_record as use_record
    -- anything else that needs to be calculated
    ,ifs.weight/power(ifs.height/100, 2) as bmi -- bmi
FROM icu_features_ AS ifs
LEFT JOIN icu_features_filtered icf
    ON icf.icustay_id = ifs.icustay_id
LEFT JOIN icu_features_unique icu
    ON icu.icustay_id = ifs.icustay_id
