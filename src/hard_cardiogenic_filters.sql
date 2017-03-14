-- exclude patients with hard cardiogenic filters
-- for each patient in echo_features
-- DROP MATERIALIZED VIEW IF EXISTS hard_cardiogenic_filters CASCADE;

CREATE MATERIALIZED VIEW hard_cardiogenic_filters AS

WITH ce_CVO2 AS (
    SELECT DISTINCT ce.icustay_id
        ,MIN(ce.valuenum) AS min_cvo2
    FROM chartevents ce
    WHERE ce.itemid IN (
         '227549' -- ScvO2 (Presep)               | metavision | Hemodynamics | % 
        ,'226541' -- ScvO2 Central Venous O2% Sat | metavision | Labs         | None
    ) AND (ce.valuenum < 60) -- at any time during icustay
    GROUP BY ce.icustay_id
)
, ce_MVO2 AS (
    SELECT DISTINCT ce.icustay_id
        ,MIN(ce.valuenum) AS min_mvo2
    FROM chartevents ce
    WHERE ce.itemid IN (
         '2265'   -- MVO2                           | carevue    | None         | None
        ,'2574'   -- MVO2 SAT                       | carevue    | None         | None
        ,'6947'   -- mvo2                           | carevue    | None         | None
    ) AND (ce.valuenum < 60) -- at any time during icustay
    GROUP BY ce.icustay_id
)
, ce_cardiac_index AS (
    SELECT DISTINCT ce.icustay_id
        ,MIN(ce.valuenum) AS min_ci
    FROM chartevents ce
    WHERE ce.itemid IN (
         '116'    -- Cardiac Index                  | carevue    | None         | None
        ,'7610'   -- cardiac index o                | carevue    | None         | None
        ,'228368' -- Cardiac Index (CI NICOM)       | metavision | NICOM        | L/min/m2
    ) AND (ce.valuenum < 2.2) -- at any time during icustay
    GROUP BY ce.icustay_id
)
, ce_cardiac_cath AS (
    SELECT DISTINCT ce.icustay_id
        , 1 AS cardiac_cath_flg
    FROM chartevents ce
    WHERE ce.itemid IN (
        '225430' -- Cardiac Cath                    | metavision | 4-procedures 
    )
)
, pi_cardiac_procedures AS (
    SELECT DISTINCT pi.hadm_id
        , 1 AS picd9_flg
    FROM procedures_icd pi
    WHERE pi.icd9_code IN (
         '66'   -- Percutaneous transluminal coronary angioplasty...
        ,'3691' -- Repair of aneurysm of coronary vessel
        ,'3603' -- Open chest coronary artery angioplasty
        ,'3604' -- Intracoronary artery thrombolytic infusion
        ,'3606' -- Insertion of non-drug-eluting coronary artery ...
        ,'3607' -- Insertion of drug-eluting coronary artery sten...
        ,'3609' -- Other removal of coronary artery obstruction
        ,'3610' -- Aortocoronary bypass for heart revascularizati...
        ,'3611' -- (Aorto)coronary bypass of one coronary artery
        ,'3612' -- (Aorto)coronary bypass   of two coronary arteries
        ,'3613' -- (Aorto)coronary bypass of three coronary arteries
        ,'3614' -- (Aorto)coronary bypass of four or more coronar...
        ,'3615' -- Single internal mammary-coronary artery bypass
        ,'3616' -- Double internal mammary-coronary artery bypass
        ,'3617' -- Abdominal-coronary artery bypass
        ,'1755' -- Transluminal coronary atherectomy 
    )
)
, ce_mech_support AS (
    SELECT DISTINCT ce.icustay_id
        , 1 AS mech_support_flg
    FROM chartevents ce
    WHERE ce.itemid IN (
         224     -- IABP Mean                               | carevue
        ,225     -- IABP setting                            | carevue
        ,429     -- LVAD Flow LPM                           | carevue
        ,5938    -- lvad svr                                | carevue
        ,2515    -- IABP-BP                                 | carevue
        ,2865    -- iabp-bp                                 | carevue
        ,6424    -- IABP BP                                 | carevue
        ,228148  -- ABI Ankle BP R (Impella)                | metavision
        ,228149  -- ABI Brachial BP L (Impella)             | metavision
        ,228154  -- Impella 2.5 Flow Rate                   | metavision
        ,228160  -- Impella Aortic Pressure Tubing Change   | metavision
        ,228162  -- Impella Catheter Position               | metavision
        ,228163  -- Impella Catheter Repositioned           | metavision
        ,228164  -- Impella Catheter Site                   | metavision
        ,228165  -- Impella Daily Tubing Change             | metavision
        ,228166  -- Impella Dressing Change                 | metavision
        ,228167  -- Impella Dressing Occlusive              | metavision
        ,228168  -- Impella Insertion Date                  | metavision
        ,228169  -- Impella Line                            | metavision
        ,228170  -- Impella Line Discontinued               | metavision
        ,228171  -- Impella Placement Confirmed             | metavision
        ,228172  -- Impella Postion Confirmed               | metavision
        ,228173  -- Impella Position                        | metavision
        ,228174  -- Impella Line Site Appear                | metavision
        ,224272  -- IABP line                               | metavision
        ,225335  -- IABP Cap Change                         | metavision
        ,225336  -- IABP Change over Wire Date              | metavision
        ,225337  -- IABP Dressing Change                    | metavision
        ,225338  -- IABP Insertion Date                     | metavision
        ,225339  -- IABP Site Appear                        | metavision
        ,225340  -- IABP Tubing Change                      | metavision
        ,225341  -- IABP Art. Waveform Appear               | metavision
        ,225342  -- IABP Zero/Calibrate                     | metavision
        ,227355  -- IABP Dressing Occlusive                 | metavision
        ,227754  -- IABP Placement Confirmed by X-ray       | metavision
        ,224314  -- ABI Brachial BP R (Impella)             | metavision
        ,224318  -- ABI Ankle BP L (Impella)                | metavision
        ,224322  -- IABP Mean                               | metavision
        ,225778  -- IABP Dressing Type                      | metavision
        ,225727  -- IABP Line Tip Cultured                  | metavision
        ,225742  -- IABP Line Discontinued                  | metavision
        ,225979  -- IABP Size                               | metavision
        ,225980  -- IABP Volume                             | metavision
        ,225981  -- IABP Alarms Activated                   | metavision
        ,225982  -- IABP Balloon Waveform                   | metavision
        ,225984  -- IABP Trigger                            | metavision
        ,225985  -- IABP Helium Tubing                      | metavision
        ,225986  -- IABP Arterial Waveform Source           | metavision
        ,225987  -- IABP Power Source                       | metavision
        ,225988  -- IABP Position on leg                    | metavision
        ,226110  -- IABP placed in outside facility         | metavision
    )
)
, ps_dobutamine AS (
    SELECT DISTINCT ps.icustay_id
        ,1 AS ps_dobutamine_flg
    FROM prescriptions ps
    WHERE (concat(ps.drug, ps.drug_name_poe, ps.drug_name_generic) ~* '.*dobutamine.*')
        -- DOBUTamine     |                 |                    | IV
        -- DOBUTamine     |                 |                    | IV DRIP
        -- DOBUTamine     |                 |                    | PB
        -- Dobutamine     |                 |                    | IV DRIP
        -- Dobutamine HCl | Dobutamine HCl  | Enoxaparin Sodium  | IV DRIP
        -- Dobutamine HCl |                 |                    | IV
        -- Dobutamine HCl |                 |                    | IV DRIP
        -- Dobutamine HCl |                 |                    | PB
        -- Dobutamine Hcl |                 |                    | IV DRIP
        -- Dobutamine Hcl |                 |                    | PB
    GROUP BY ps.icustay_id
)
, ps_milrinone AS (
    SELECT DISTINCT ps.icustay_id
        ,1 AS ps_milrinone_flg
    FROM prescriptions ps
    WHERE (concat(ps.drug, ps.drug_name_poe, ps.drug_name_generic) ~* '.*milrinone.*')
        -- Milrinone         | Milrinone       | Milrinone Lactate  | IV
        -- Milrinone         | Milrinone       | Milrinone Lactate  | IV BOLUS
        -- Milrinone         | Milrinone       | Milrinone Lactate  | IV DRIP
        -- Milrinone         |                 |                    | IV
        -- Milrinone         |                 |                    | IV BOLUS
        -- Milrinone         |                 |                    | IV DRIP
        -- Milrinone         |                 |                    | PB
        -- Milrinone Lactate |                 |                    | IV
        -- Milrinone Lactate |                 |                    | IV DRIP
    GROUP BY ps.icustay_id
)

SELECT ic.icustay_id
    ,ce_cv.min_cvO2 IS NOT NULL AS ce_cvO2 
    ,ce_mv.min_mvO2 IS NOT NULL AS ce_mvO2
    ,ce_ci.min_ci IS NOT NULL AS ce_ci
    ,ce_cc.cardiac_cath_flg IS NOT NULL AS ce_cardiac_cath_flg
    ,ce_ms.mech_support_flg IS NOT NULL AS ce_mech_support_flg
    ,pi.picd9_flg IS NOT NULL AS pi_icd9_flg
    ,ps_dobutamine.ps_dobutamine_flg IS NOT NULL AS ps_dobutamine_flg
    ,ps_milrinone.ps_milrinone_flg IS NOT NULL AS ps_milrinone_flg
    --
    --  any_flg | count
    -- ---------+-------
    --  f       | 51376
    --  t       | 10156
    ,((ce_cv.min_cvO2 IS NOT NULL) OR
      (ce_mv.min_mvO2 IS NOT NULL) OR
      (ce_ci.min_ci IS NOT NULL) OR 
      (ce_cc.cardiac_cath_flg IS NOT NULL) OR
      (ce_ms.mech_support_flg IS NOT NULL) OR 
      (pi.picd9_flg IS NOT NULL) OR
      (ps_dobutamine.ps_dobutamine_flg IS NOT NULL) OR
      (ps_milrinone.ps_milrinone_flg IS NOT NULL)
     ) AS any_flg
FROM icustays ic
LEFT JOIN ce_CVO2 ce_cv
    ON ic.icustay_id = ce_cv.icustay_id
LEFT JOIN ce_MVO2 ce_mv
    ON ic.icustay_id = ce_mv.icustay_id
LEFT JOIN ce_cardiac_index ce_ci
    ON ic.icustay_id = ce_ci.icustay_id
LEFT JOIN ce_cardiac_cath ce_cc
    ON ic.icustay_id = ce_cc.icustay_id
LEFT JOIN ce_mech_support ce_ms
    ON ic.icustay_id = ce_ms.icustay_id
LEFT JOIN pi_cardiac_procedures pi
    ON ic.hadm_id = pi.hadm_id
LEFT JOIN ps_dobutamine 
    ON ic.icustay_id = ps_dobutamine.icustay_id
LEFT JOIN ps_milrinone
    ON ic.icustay_id = ps_milrinone.icustay_id
