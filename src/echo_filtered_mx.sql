set search_path to mimiciii;
-- for a clean copy of echo_filtered, run in order
-- echo_icustay (25512)
-- diagnoses_xc_annot (392)
-- d_prescriptions_vaso (49)
-- echo_outpatient (4385)
-- echo_filter_vars (25512)
-- echo_features_mx (25512)

DROP MATERIALIZED VIEW IF EXISTS echo_filtered_mx CASCADE;

CREATE MATERIALIZED VIEW echo_filtered_mx AS 

WITH 
  passes_filters AS (
    SELECT *
        , DENSE_RANK() OVER (PARTITION BY ef.subject_id ORDER BY ef.ed_charttime) AS echo_seq 
    FROM echo_features_mx ef
    WHERE (
            ef.ps_vaso = True 
        AND ef.diag_xc = False
        AND ef.time_filter = True
        AND ef.age_filter = True
        and ef.chronic_dialysis_flg = False
    ) 
)
SELECT *
FROM passes_filters pf
-- subject_id can only be included once, use the earliest echo
WHERE pf.echo_seq = 1
