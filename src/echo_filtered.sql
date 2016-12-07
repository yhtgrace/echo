DROP MATERIALIZED VIEW IF EXISTS echo_filtered CASCADE;

CREATE MATERIALIZED VIEW echo_filtered AS 

WITH 
  passes_filters AS (
    SELECT *
        , DENSE_RANK() OVER (PARTITION BY ef.subject_id ORDER BY ef.admittime DESC) 
          AS most_recent_hadm
    FROM echo_features ef
    WHERE (
            ef.ps_vaso = True 
        AND ef.diag_xc = False
        AND ef.time_filter = True
        AND ef.age_filter = True
    ) 
)
, most_recent_hadm AS (
    SELECT * 
    FROM passes_filters
    WHERE most_recent_hadm = 1
)
, first_echo AS (
    SELECT * 
        , DENSE_RANK() OVER (PARTITION BY mh.subject_id ORDER BY mh.ed_charttime) 
          AS first_echo
    FROM most_recent_hadm mh
)
SELECT * FROM first_echo
WHERE first_echo = 1
