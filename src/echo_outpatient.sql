DROP MATERIALIZED VIEW IF EXISTS echo_outpatient CASCADE;

CREATE MATERIALIZED VIEW echo_outpatient AS 

-- for all outpatient echos, pair with inpatient echos by matching on
-- subject_id
WITH pairs AS (
    SELECT 
         ed.row_id AS op_rowid, -- echo_data row_id of the outpatient echo 
         ei.row_id AS icu_rowid -- echo_data row_id of the inpatient icustay echo
        ,ed.charttime AS op_charttime -- chart time of the outpatient echo
        ,ei.charttime AS icu_charttime -- chart time of the inpatient icustay echo
        ,ei.subject_id 
        ,ei.icustay_id
        -- if the outpatient echo occurred after the inpatient icustay echo
        ,CASE WHEN ed.charttime > ei.charttime THEN 1 ELSE 0 END AS op_after
        ,ei.charttime - ed.charttime AS icu_to_op
        -- if the outpatient echo occured before the inpatient icustay echo
        ,CASE WHEN ed.charttime < ei.charttime THEN 1 ELSE 0 END AS op_before
        ,ed.charttime - ei.charttime AS op_to_icu
        -- enumerate quality
        ,CASE WHEN ed.technicalquality = 'Good' THEN 3
              WHEN ed.technicalquality = 'Adequate' THEN 2
              WHEN ed.technicalquality = 'Suboptimal' THEN 1
         ELSE 0 END AS tq
    FROM echodata ed
    INNER JOIN echo_icustay ei
        ON ei.subject_id = ed.subject_id
    WHERE   
            ed.status = 'Outpatient' 
        AND ed.hadm_id IS NULL
)
-- for each inpatient icustay echo, find the most proximal outpatient echo 
-- that occured after 
, proximal_after AS (
    SELECT ps.icu_rowid, MIN(ps.op_to_icu) AS op_to_icu
    FROM pairs ps
    WHERE ps.op_after = 1
    GROUP BY ps.icu_rowid
)
, proximal_after_ AS (
    SELECT ps.* FROM proximal_after pa
    INNER JOIN pairs ps
        ON pa.icu_rowid = ps.icu_rowid
        AND pa.op_to_icu = ps.op_to_icu
)
-- for each inpatient icustay echo, find the most proximal outpatient echo
-- that occured before
, proximal_before AS (
    SELECT ps.icu_rowid, MIN(ps.icu_to_op) AS icu_to_op
    FROM pairs ps
    WHERE ps.op_before = 1
    GROUP BY ps.icu_rowid
)
, proximal_before_ AS (
    SELECT ps.* FROM proximal_before pb
    INNER JOIN pairs ps
        ON pb.icu_rowid = ps.icu_rowid
        AND pb.icu_to_op = ps.icu_to_op
)
-- for each inpatient icustay echo, get the best quality most proximal outpatient echo
-- that ocurred after
, proximal_quality_after AS (
    SELECT pa.icu_rowid, MAX(tq) AS tq FROM proximal_after_ pa
    GROUP BY pa.icu_rowid
)
, proximal_quality_after_ AS (
    SELECT pa.* FROM proximal_quality_after pqa
    INNER JOIN proximal_after_ pa
        ON pqa.icu_rowid = pa.icu_rowid
        AND pqa.tq = pa.tq
)
-- for each inpatient icustay echo, get the best quality most proximal outpatient echo
-- that ocurred before
, proximal_quality_before AS (
    SELECT pb.icu_rowid, MAX(tq) AS tq FROM proximal_before_ pb
    GROUP BY pb.icu_rowid
)
, proximal_quality_before_ AS (
    SELECT pb.* FROM proximal_quality_before pqb
    INNER JOIN proximal_before_ pb
        ON pqb.icu_rowid = pb.icu_rowid
        AND pqb.tq = pb.tq
)
-- each inpatient icustay echo should occur once in pqa and pqb
-- therefore do a full outer join over the two tables on icu_rowid 
SELECT 
    CASE WHEN pqa.icu_rowid IS NOT NULL THEN pqa.icu_rowid ELSE pqb.icu_rowid END AS icu_rowid
    ,pqa.op_rowid AS after_rowid
    ,pqb.op_rowid AS before_rowid
    ,pqa.op_to_icu AS op_to_icu
    ,pqb.icu_to_op AS icu_to_op
FROM proximal_quality_after_ pqa
FULL OUTER JOIN proximal_quality_before_ pqb
    ON pqa.icu_rowid = pqb.icu_rowid
