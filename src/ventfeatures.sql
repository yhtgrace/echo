
DROP TABLE IF EXISTS ventfeatures CASCADE;
CREATE TABLE ventfeatures AS

WITH diff AS(
    SELECT (efv.charttime - vt.charttime) 
    FROM echo_filter_vars efv
    LEFT JOIN venttype vt
        ON vt.icustay_id = efv.icustay_id
)

SELECT
    efv.row_id, efv.icustay_id, efv.hadm_id, efv.subject_id
    -- -12 hours <= time of echo - time of vent flag <= 12 hours
    , max(
        case 
        when (((efv.charttime - vt.charttime) > INTERVAL '-12 hours') AND
              ((efv.charttime - vt.charttime) < INTERVAL '12 hours')) THEN 1
        else 0
        end
    ) as noninv_vent
    -- mech vent duration over echo chartime
    , max(
        case 
        when ((vd.starttime <= efv.charttime) AND
              (vd.endtime >= efv.charttime)) THEN 1
        else 0
        end
    ) as mech_vent
    
FROM echo_filter_vars efv
LEFT JOIN venttype vt
    ON vt.icustay_id = efv.icustay_id
LEFT JOIN ventdurations vd
    ON vd.icustay_id = efv.icustay_id
GROUP BY efv.row_id, efv.icustay_id, efv.hadm_id, efv.subject_id

