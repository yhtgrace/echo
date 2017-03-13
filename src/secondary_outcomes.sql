--DROP MATERIALIZED VIEW IF EXISTS secondary_outcomes CASCADE;

CREATE MATERIALIZED VIEW secondary_outcomes AS 

WITH max_creatinine AS (
    SELECT ls.icustay_id, MAX(valuenum) AS max_valuenum
    FROM labs ls
    WHERE label = 'CREATININE'
    GROUP BY ls.icustay_id, label
)

, max_lactate AS (
    SELECT ls.icustay_id, MAX(valuenum) AS max_valuenum
    FROM labs ls
    WHERE label = 'LACTATE'
    GROUP BY ls.icustay_id, label
)

, last_creatinine AS (
    SELECT DISTINCT ON (icustay_id)
        ls.icustay_id, ls.valuenum, ls.charttime
    FROM labs ls
    WHERE label = 'CREATININE'
    ORDER BY icustay_id, charttime DESC
)

, last_lactate AS (
    SELECT DISTINCT ON (icustay_id)
        ls.icustay_id, ls.valuenum, ls.charttime
    FROM labs ls
    WHERE label = 'LACTATE'
    ORDER BY icustay_id, charttime DESC
)

SELECT ic.icustay_id
    ,mc.max_valuenum AS creatinine_max
    ,ml.max_valuenum AS lactate_max
    ,lc.valuenum AS creatinine_last
    ,ll.valuenum AS lactate_last
FROM icustays as ic
LEFT JOIN max_creatinine mc
    ON ic.icustay_id = mc.icustay_id
LEFT JOIN max_lactate ml
    ON ic.icustay_id = ml.icustay_id
LEFT JOIN last_creatinine lc
    ON ic.icustay_id = lc.icustay_id
LEFT JOIN last_lactate ll
    ON ic.icustay_id = ll.icustay_id
