DROP MATERIALIZED VIEW IF EXISTS secondary_outcomes CASCADE;

CREATE MATERIALIZED VIEW secondary_outcomes AS 

WITH lab_last as(
    select distinct on (subject_id, hadm_id, icustay_id, label)
        subject_id, hadm_id, icustay_id, label, valuenum
    from (select subject_id, hadm_id, icustay_id, charttime, label
            , avg(valuenum) as valuenum
          from labs
          group by subject_id, hadm_id, icustay_id, charttime, label
    ) as sub
    order by subject_id, hadm_id, icustay_id, label, charttime desc
)

, lab_max as(
    select subject_id, hadm_id, icustay_id, label
        , max(valuenum) as valuenum
    from labs
    group by subject_id, hadm_id, icustay_id, label
)

, lab_both as(
    select ll.subject_id, ll.hadm_id, ll.icustay_id, ll.label
        , ll.valuenum as last_
        , lm.valuenum as max_
    from lab_last ll
    inner join lab_max lm
        on ll.icustay_id = lm.icustay_id
        AND ll.label = lm.label
)

, creatinine as(
    select subject_id, hadm_id, icustay_id
        , last_ as creatinine_last
        , max_ as creatinine_max
    from lab_both
    where label = 'CREATININE'
)

, lactate as(
    select subject_id, hadm_id, icustay_id
        , last_ as lactate_last
        , max_ as lactate_max
    from lab_both
    where label = 'LACTATE'
)

SELECT c.subject_id, c.hadm_id, c.icustay_id
    , c.creatinine_last, c.creatinine_max
    , l.lactate_last, l.lactate_max
FROM creatinine c
INNER JOIN lactate l
    ON c.icustay_id = l.icustay_id











