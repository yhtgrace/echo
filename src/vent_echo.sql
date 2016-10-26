-- Create a flag indicating whether the patient was on -- a ventilator when echo was taken
DROP MATERIALIZED VIEW IF EXISTS vent_echo CASCADE; 

CREATE MATERIALIZED VIEW vent_echo AS  

WITH vent_echo AS (

    SELECT echo.row_id, echo.charttime
    --ventilator flags
    , ((vent.starttime <= echo.charttime) AND (vent.endtime >= echo.charttime)) AS on_ventilator_during_echo
    , True AS on_ventilator_anytime
    FROM echo_icustay echo
    INNER JOIN ventdurations vent 
        ON echo.icustay_id = vent.icustay_id
),

vent_echo_unique AS (
    
    SELECT row_id
    , bool_or(on_ventilator_during_echo) as on_ventilator_during_echo
    , bool_or(on_ventilator_anytime) as on_ventilator_anytime
    FROM vent_echo
    GROUP BY row_id

)

SELECT echo.row_id
, COALESCE(vent.on_ventilator_during_echo, False) as on_ventilator_during_echo
, COALESCE(vent.on_ventilator_anytime, False) as on_ventilator_anytime
FROM echo_icustay echo
LEFT JOIN vent_echo_unique vent
    ON echo.row_id = vent.row_id



