DROP MATERIALIZED VIEW IF EXISTS echo_filtered CASCADE;

CREATE MATERIALIZED VIEW echo_filtered AS 

WITH add_filters AS (
    SELECT *
        -- time filter: echo within -8 to 48 hours of ICU stay
        , ((ev.intime_to_echo > INTERVAL '-8 hours') AND 
           (ev.intime_to_echo < INTERVAL '48 hours')) AS time_filter
        , (ev.age_at_intime > INTERVAL '18 years') AS age_filter
    FROM echo_filter_vars ev
)

SELECT * 
FROM add_filters ef
WHERE (
        ef.ps_vaso = True 
    AND ef.diag_xc = False
    AND ef.time_filter = True
    AND ef.age_filter = True
) 

