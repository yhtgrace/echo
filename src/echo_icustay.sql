DROP MATERIALIZED VIEW IF EXISTS echo_icustay CASCADE;

CREATE MATERIALIZED VIEW echo_icustay AS

-- assign icustay_id to each echo
-- by associating echos to hadm_ids
-- and finding the icustay_id where the echo charttime is between (intime - 8h, outtime)
-- this also filters for echos to which an icustay_id can be assigned
SELECT 
    ed.row_id, ed.charttime 
    ,ie.icustay_id, ie.intime, ie.outtime, ie.hadm_id
FROM echodata ed
INNER JOIN icustays ie
    ON ie.hadm_id = ed.hadm_id
    WHERE (ed.charttime > (ie.intime - INTERVAL '8 hours')) AND (ed.charttime < ie.outtime)
