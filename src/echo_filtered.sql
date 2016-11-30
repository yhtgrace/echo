DROP MATERIALIZED VIEW IF EXISTS echo_filtered CASCADE;

CREATE MATERIALIZED VIEW echo_filtered AS 

SELECT * 
FROM echo_filter_vars ef
WHERE (
        ef.ps_vaso = True 
    AND ef.diag_xc = False
    AND ef.time_filter = True
    AND ef.age_filter = True
) 

