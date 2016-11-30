DROP MATERIALIZED VIEW IF EXISTS echo_icustay CASCADE;

CREATE MATERIALIZED VIEW echo_icustay AS

-- get echos to which an icustay_id can be assigned
-- an echo is associated to an icustay_id by first associating the icustay with matching hadm_id
-- where the echo charttime is between (intime - 8h, outtime)
WITH echo_assigned AS ( 
    SELECT 
        ed.row_id, ed.charttime 
        ,ie.icustay_id, ie.hadm_id, ie.subject_id, ie.intime, ie.outtime
    FROM echodata ed
    INNER JOIN icustays ie
        ON ie.hadm_id = ed.hadm_id
        WHERE (ed.charttime > (ie.intime - INTERVAL '8 hours')) AND (ed.charttime < ie.outtime)
)
SELECT * FROM echo_assigned
