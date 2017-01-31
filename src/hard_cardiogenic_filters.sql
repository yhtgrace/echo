-- exclude patients with hard cardiogenic filters
-- for each patient in echo_features
DROP MATERIALIZED VIEW IF EXISTS hard_cardiogenic_filters CASCADE;

CREATE MATERIALIZED VIEW hard_cardiogenic_filters AS 
(
    SELECT subject_id, hadm_id, icustay_id
    , CASE
        when itemid = '143' THEN 'CVO2'
        ELSE NULL
    END as label
    , valuenum
    FROM chartevents ce
    WHERE itemid in 
    (
         '143'      -- CVO2, CVO2, Carevue
        ,'226860'   -- RA %O2 Saturation (PA Line), CVO2, Metavision
        ,'227549'   -- ScvO2 (Presep), CVO2, Metavision
        ,'226541'   -- ScvO2 Central Venous O2% Sat, CVO2, Metavision
        ,'2265'     -- MVO2, MVO2, Carevue
        ,'2574'     -- MVO2 SAT, MVO2, Carevue
        ,'6947'     -- mvo2, MVO2, Carevue
        ,'226862'   -- PA %O2 Saturation (PA Line), MVO2, Metavision 
    )
    AND valuenum IS NOT NULL 
)

