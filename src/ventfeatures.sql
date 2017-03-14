
-- DROP MATERIALIZED VIEW IF EXISTS ventfeatures CASCADE;
CREATE MATERIALIZED VIEW ventfeatures AS

WITH first_day_vent AS( 
    SELECT
        vd.icustay_id
        -- on ventilator within -6 to +24 hourse of ICU admission
        , 1 as mech_vent
        
    FROM ventdurations vd
    LEFT JOIN icustays ic
        on vd.icustay_id = ic.icustay_id
    -- only select ventilator events that overlap with -6 to +24 hours of ICU admission
    WHERE ((((vd.starttime - ic.intime) >= INTERVAL '0 hours') AND
           ((vd.starttime - ic.intime) <= INTERVAL '24 hours')) OR
          (((vd.endtime - ic.intime) >= INTERVAL '0 hours') AND
           ((vd.endtime - ic.intime) <= INTERVAL '24 hours')) OR
          ((ic.intime >= vd.starttime) AND (ic.intime <= vd.endtime)))
          AND (vd.duration_hours > 0) --for some labels duration is 0? these are errors? 
    GROUP BY vd.icustay_id
), duration AS(
    SELECT
        vd.icustay_id
        , sum(vd.duration_hours) as duration
    FROM ventdurations vd
    GROUP BY icustay_id
)

SELECT
    ic.icustay_id
    , case
        when fdv.mech_vent = 1 then 1
        else 0
      end as first_day_vent
    , case
        when d.duration is not null then d.duration
        else 0
      end as duration
FROM icustays ic
LEFT JOIN first_day_vent fdv
    on ic.icustay_id = fdv.icustay_id
LEFT JOIN duration d
    on ic.icustay_id = d.icustay_id


