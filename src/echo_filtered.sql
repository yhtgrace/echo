-- for a clean copy of echo_filtered, run in order
-- echo_icustay (25512)
-- d_diagnoses_xc_annot (392)
-- d_prescriptions_vaso (49)
-- echo_outpatient (4385)
-- echo_filter_vars (25512)
-- echo_filtered (1932) 

DROP MATERIALIZED VIEW IF EXISTS echo_filtered CASCADE;

CREATE MATERIALIZED VIEW echo_filtered AS 

WITH 
  passes_filters AS (
    SELECT *
        , DENSE_RANK() OVER (PARTITION BY ef.subject_id ORDER BY ef.charttime) AS echo_seq 
    FROM echo_filter_vars ef
    WHERE (
            ef.ps_vaso = True 
        AND ef.diag_xc = False
        AND ef.time_filter = True
        AND ef.age_filter = True
    ) 
)
SELECT *
FROM passes_filters pf
-- subject_id can only be included once, use the earliest echo
WHERE pf.echo_seq = 1
