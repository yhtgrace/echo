DROP MATERIALIZED VIEW IF EXISTS echo_filter CASCADE;

CREATE MATERIALIZED VIEW echo_filter AS

WITH
-- determine if an echo_icustay is associated with a vasopressor  
  echo_vaso AS (
    SELECT DISTINCT ps.icustay_id
        , 1 AS ps_vaso
    FROM prescriptions ps 
    INNER JOIN echo_icustay ei
        ON ei.icustay_id = ps.icustay_id
    INNER JOIN d_prescriptions_vaso dpv
        ON ( ps.drug                IS NOT DISTINCT FROM dpv.drug
         AND ps.drug_name_poe       IS NOT DISTINCT FROM dpv.drug_name_poe
         AND ps.drug_name_generic   IS NOT DISTINCT FROM dpv.drug_name_generic
         AND ps.route               IS NOT DISTINCT FROM dpv.route )
)
-- compute new variables
, echo_ext AS (
    SELECT ei.*
        -- time of echo wrt icustay intime and outtime
        ,(ei.charttime - ei.intime) AS intime_to_echo
        ,(ei.outtime - ei.charttime) AS echo_to_outtime
        -- whether or not patient was on a vasopressor during the icustay
        ,ev.ps_vaso IS NOT NULL AS ps_vaso
        -- age on admission to the icu
        ,age(ei.intime, pt.dob) AS age_at_intime
    FROM echo_icustay ei
    LEFT JOIN echo_vaso ev
        ON ei.icustay_id = ev.icustay_id
    INNER JOIN icustays ic
        ON ei.icustay_id = ic.icustay_id
    INNER JOIN patients pt
        ON ic.subject_id = pt.subject_id
)
-- proposed filters
, add_filters AS (
    SELECT *
        -- time filter: echo within -8 to 48 hours of ICU stay
        , ((ee.intime_to_echo > INTERVAL '-8 hours') AND 
           (ee.intime_to_echo < INTERVAL '48 hours')) AS time_filter
    FROM echo_ext ee
)
SELECT * FROM add_filters
