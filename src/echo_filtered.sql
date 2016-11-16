DROP MATERIALIZED VIEW IF EXISTS echo_filtered CASCADE;

CREATE MATERIALIZED VIEW echo_filtered AS 

WITH add_filters AS (
    SELECT *
        -- time filter: echo within -8 to 48 hours of ICU stay
        , ((ev.intime_to_echo > INTERVAL '-8 hours') AND 
           (ev.intime_to_echo < INTERVAL '48 hours')) AS time_filter
    FROM echo_filter_vars ev
)

SELECT * 
FROM add_filters ef
WHERE (
        ef.ps_vaso = True 
    AND ef.diag_xc = False
    AND ef.time_filter = True
) 

-- COUNT(DISTINCT subject_id) WHERE (ef.ps_vaso = True); 7897
-- COUNT(DISTINCT subject_id) WHERE (ef.diag_xc = False); 4937
-- COUNT(DISTINCT subject_id) WHERE (ef.diag_xc = False AND ef.ps_vaso = True); 2277
-- COUNT(DISTINCT subject_id) WHERE (ef.ps_vaso = True AND ef.diag_xc = False AND ef.time_filter = True); 1944
