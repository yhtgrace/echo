DROP MATERIALIZED VIEW IF EXISTS echo_icustay CASCADE;

CREATE MATERIALIZED VIEW echo_icustay AS

-- assign icustay_id to each echo
-- by associating echos to hadm_ids
-- and finding the icustay_id where the echo charttime is between (intime - 8h, outtime)
-- this also filters for echos to which an icustay_id can be assigned
WITH echo_assigned AS ( 
    SELECT 
        ed.row_id, ed.charttime 
        ,ie.icustay_id, ie.intime, ie.outtime, ie.hadm_id
        ,(ed.charttime - ie.intime) AS time_to_echo
    FROM echodata ed
    INNER JOIN icustays ie
        ON ie.hadm_id = ed.hadm_id
        WHERE (ed.charttime > (ie.intime - INTERVAL '8 hours')) AND (ed.charttime < ie.outtime)
)
-- the current proposed sequence of filters starts with filtering for the echo in 
-- the first 48 hours of ICU stay, and then filtering for echos which can be associated
-- with distributive shock
, add_filters AS (
    SELECT *
        , ((ea.time_to_echo > INTERVAL '-8 hours') AND 
           (ea.time_to_echo < INTERVAL '48 hours')) AS time_filter
    FROM echo_assigned ea
)
SELECT * FROM add_filters
