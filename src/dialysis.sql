-- Modified rrt.sql to give chartdates associated with every dialysis event

CREATE MATERIALIZED VIEW dialysis as 

WITH cv AS ( 
SELECT ce.subject_id, ce.hadm_id, ce.icustay_id, ce.itemid, ce.charttime 
    , ce.charttime::timestamp::date as chartdate
    , 'carevue'::text as dbsource
FROM icustays ie
INNER JOIN chartevents ce
    ON ie.icustay_id = ce.icustay_id
WHERE ( ce.itemid in (
         152 -- Dialysis Type
        ,148 -- Dialysis Access Site
        ,149 -- Dialysis Access Type
        ,146 -- Dialysate Flow ml/hr
        ,147 -- Dialysate Infusing
        ,151 -- Dialysis Site Appear
        ,150 -- Dialysis Machine
    ) OR ( ce.itemid in (
         229 -- INV Line#1
        ,235 -- INV Line#2
        ,241 -- INV Line#3
        ,247 -- INV Line#4
        ,253 -- INV Line#5
        ,259 -- INV Line#6
        ,265 -- INV Line#7
        ,271 -- INV Line#8
        ) 
        AND ce.value = 'Dialysis Line'
    ) OR ( ce.itemid = 582 -- Procedures
        AND ce.value in (
             'CAVH Start'
            ,'CAVH D/C'
            ,'CVVHD Start'
            ,'CVVHD D/C'
            ,'Hemodialysis st'
            ,'Hemodialysis end'))
    ) 
AND ie.dbsource = 'carevue'
) 

, mv_ce AS ( 
SELECT subject_id, hadm_id, icustay_id, itemid, charttime
    , charttime::timestamp::date as chartdate
    , 'metavision'::text as dbsource
FROM chartevents 
WHERE itemid in (
    -- Checkboxes
     225126 -- Dialysis Patient
    ,226118 -- Dialysis Catheter placed in outside facility
    ,227357 -- Dialysis Catheter Dressing Occlusive
    ,225725 -- Dialysis Catheter Tip Cultured
    -- Numeric values
    ,226499 -- Hemodialysis output
    ,224154 -- Dialysate Rate
    ,225810 -- Dwell time (Peritoneal Dialysis)
    ,227639 -- Medication Added Amount #2 (Peritoneal Dialysis)
    ,225183 -- Current goal 
    ,227438 -- Volume not removed 
    ,224191 -- Hourly Patient Fluid Removal 
    ,225806 -- Volume In (PD)
    ,225807 -- Volume Out (PD)
    ,228004 -- Citrate (ACD-A)
    ,228005 -- PBP (Prefilter) Replacement Rate
    ,228006 -- Post Filter Replacement Rate 
    ,224144 -- Blood Flow (ml/min)
    ,224145 -- Heparin Dose (per hour)
    ,224149 -- Access Pressure
    ,224150 -- Filter Pressure
    ,224151 -- Effluent Pressure
    ,224152 -- Return Pressure
    ,224153 -- Replacement Rate
    ,224404 -- ART Lumen Volume
    ,224406 -- VEN Lumen Volume
    ,226457 -- Ultrafiltrate Output
) 
AND valuenum > 0 -- not null
)

, mv_ie AS (
SELECT subject_id, hadm_id, icustay_id, itemid 
    , starttime as charttime
    , starttime::timestamp::date as chartdate -- endtime is also available
    , 'metavision'::text as dbsource
FROM inputevents_mv
WHERE itemid in (
     227536 -- KCl (CRRT)
    ,227525 -- Calcium Gluconate (CRRT) 
)
AND amount > 0 -- not null
)

, mv_de AS (
SELECT subject_id, hadm_id, icustay_id, itemid, charttime
    , charttime::timestamp::date as chartdate 
    , 'metavision'::text as dbsource
FROM datetimeevents
WHERE itemid in (
     225318 -- Dialysis Catheter Cap Change
    ,225319 -- Dialysis Catheter Change over Wire Date
    ,225321 -- Dialysis Catheter Dressing Change
    ,225322 -- Dialysis Catheter Insertion Date
    ,225324 -- Dialysis Catheter Tubing Change
    -- 225128 -- Last Dialysis
)
)

, mv_pe AS (
SELECT subject_id, hadm_id, icustay_id, itemid
    , starttime as charttime
    , starttime::timestamp::date as chartdate -- endtime is also available
    , 'metavision'::text as dbsource
FROM procedureevents_mv
WHERE itemid in (
     225441 -- Hemodialysis
    ,225802 -- Dialysis - CRRT
    ,225803 -- Dialysis - CVVHD
    ,225805 -- Peritoneal Dialysis
    ,224270 -- Dialysis Catheter
    ,225809 -- Dialysis - CVVHDF
    ,225955 -- Dialysis - SCUF
    ,225436 -- CRRT Filter Change
)
)

SELECT subject_id, hadm_id, icustay_id, itemid, charttime, dbsource
FROM cv
UNION ALL
SELECT subject_id, hadm_id, icustay_id, itemid, charttime, dbsource
FROM mv_ce
UNION ALL
SELECT subject_id, hadm_id, icustay_id, itemid, charttime, dbsource
FROM mv_ie
UNION ALL
SELECT subject_id, hadm_id, icustay_id, itemid, charttime, dbsource
FROM mv_de
UNION ALL
SELECT subject_id, hadm_id, icustay_id, itemid, charttime, dbsource
FROM mv_pe
