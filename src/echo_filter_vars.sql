DROP MATERIALIZED VIEW IF EXISTS echo_filter_vars CASCADE;

CREATE MATERIALIZED VIEW echo_filter_vars AS

WITH
  echo_vaso AS (
    SELECT DISTINCT ps.icustay_id
        , 1 AS ps_vaso
    FROM prescriptions ps 
    INNER JOIN echo_icustay ei
        ON ei.icustay_id = ps.icustay_id -- join on icustay_id
    INNER JOIN d_prescriptions_vaso dpv
        ON ( ps.drug                IS NOT DISTINCT FROM dpv.drug
         AND ps.drug_name_poe       IS NOT DISTINCT FROM dpv.drug_name_poe
         AND ps.drug_name_generic   IS NOT DISTINCT FROM dpv.drug_name_generic
         AND ps.route               IS NOT DISTINCT FROM dpv.route )
)
, echo_diagnosis_xc AS (
    SELECT DISTINCT ei.hadm_id
        , 1 as diag_xc
    FROM d_diagnoses_xc_annot dx
    INNER JOIN diagnoses_icd di
        ON di.icd9_code = dx.icd9_code
    INNER JOIN echo_icustay ei
        ON di.hadm_id = ei.hadm_id -- join on hadm_id 
    WHERE dx.exclude = 1
)
-- compute new variables
, echo_ext AS (
    SELECT ei.*
        -- time of echo wrt icustay intime and outtime
        ,(ei.charttime - ei.intime) AS intime_to_echo
        ,(ei.outtime - ei.charttime) AS echo_to_outtime
        -- whether or not patient was on a vasopressor during the icustay
        ,ev.ps_vaso IS NOT NULL AS ps_vaso
        -- whether or not patient has an excluded diagnosis during the hospital admission
        ,edx.diag_xc IS NOT NULL as diag_xc
        -- age on admission to the icu
        ,age(ei.intime, pt.dob) AS age_at_intime
        ,pt.dob AS dob
    FROM echo_icustay ei
    LEFT JOIN echo_vaso ev
        ON ei.icustay_id = ev.icustay_id
    LEFT JOIN echo_diagnosis_xc edx
        ON ei.hadm_id = edx.hadm_id
    INNER JOIN icustays ic
        ON ei.icustay_id = ic.icustay_id
    INNER JOIN patients pt
        ON ic.subject_id = pt.subject_id
)
SELECT * FROM echo_ext

