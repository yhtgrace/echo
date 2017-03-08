set search_path to mimiciii;

DROP MATERIALIZED VIEW IF EXISTS procedures CASCADE;

CREATE MATERIALIZED VIEW procedures AS 

WITH procedure_mv AS 
(
  SELECT subject_id, icustay_id, cast(itemid as int) as code,--starttime, endtime, itemid, value, location
  CASE WHEN itemid in (
	225752	--Arterial Line
	) then 1 else 0 END AS ArterialLine,	
  CASE WHEN itemid in (	
	225400	--Bronchoscopy
	) then 1 else 0 END AS Bronch, 	
  CASE WHEN itemid in (
	225430	--Cardiac Cath
	) then 1 else 0 END AS Cath, 	
  CASE WHEN itemid in (	
	224263	--Multi Lumen
	,224264	--PICC Line
	,224267	--Cordis/Introducer
	,227719	--AVA Line
	,224268	--Trauma line
	,225315	--Tunneled (Hickman) Line
	,227551	--Plasma Pheresis.
	,225199	--Triple Introducer
	,225203	--Pheresis Catheter
	) then 1 else 0 END AS CVC, 		
  CASE WHEN itemid in (	
	225441	--Hemodialysis
	,225802	--Dialysis - CRRT
	,224270	--Dialysis Catheter
	,225805	--Peritoneal Dialysis
	,225436	--CRRT Filter Change
	) then 1 else 0 END AS Dialysis, 		
 CASE WHEN itemid in (	
	225432	--Transthoracic Echo
	) then 1 else 0 END AS Echo, 		
 CASE WHEN itemid in (	
	224272	--IABP line
	) then 1 else 0 END AS IABP, 		
 CASE WHEN itemid in (	
	228169	--Impella Line
	) then 1 else 0 END AS Impella, 		
 CASE WHEN itemid in (	
	224560	--PA Catheter
	,224269	--CCO PAC
	) then 1 else 0 END AS PAC, 		
 CASE WHEN itemid in (	
	225202	--Indwelling Port (PortaCath)
	) then 1 else 0 END AS Port, 		
 CASE WHEN itemid in (	
	225792	--Invasive Ventilation
	,227194	--Extubation
	,224385	--Intubation
	,225468	--Unplanned Extubation (patient-initiated)
	,225477	--Unplanned Extubation (non-patient initiated)
	,225794	--Non-invasive Ventilation
	) then 1 else 0 END AS Vent, 	
CASE WHEN itemid in (
	225430	--Cardiac Cath
	,224272	--IABP line
	,228169	--Impella Line	
	) then 1 else 0 END AS toexclude,
0 as pressor, 0 as rhc, 0 as thora		
  FROM mimiciii.procedureevents_mv 	
)
, procedures_icd AS (
SELECT subject_id, cast(null as int) as icustay_id, cast(icd9_code as int) as code, 
  CASE WHEN cast(cast(icd9_code as int) as int) in (
	3891, --Arterial catheterization
	8960, -- Cnt intraart bld gas mon
	8961 --Arterial pressure monit
	) then 1 else 0 END AS ArterialLine,
CASE WHEN cast(cast(icd9_code as int) as int) in (
	3324, --Closed bronchial biopsy
	3322, --Fiber-optic bronchoscopy
	3323, --Other bronchoscopy
	3321, --Bronchoscopy thru stoma
	9656,	-- Bronch/trach lavage NEC
	3348,	--Bronchial repair NEC
	3391,	--Bronchial dilation
	3329,	--Bronch/lung dx proc NEC
	3378,	--Endo rem bronch devc/sub
	3379,	--Endo insrt bronc def/sub
	3342,	--Bronchial fistula clos
	3371	--Endo ins/re bron val 
	) then 1 else 0 END AS Bronch, 	
CASE WHEN cast(icd9_code as int) in (
	3615,	--1 int mam-cor art bypass
	8856,	--Coronar arteriogr-2 cath
	3722,	--	Left heart cardiac cath
	3723,	--	Rt/left heart card cath
	8853,	--	Lt heart angiocardiogram
	66,	--	PTCA
	3606,	--	Ins nondrug elut cor st
	3607,	--	Ins drug-elut coronry st
	8855,	--	Coronar arteriogr-1 cath
	8857,	--	Coronary arteriogram NEC
	8854,	--	Rt & lt heart angiocard
	24	--	IVUS coronary vessels
	) then 1 else 0 END AS Cath,  -- **exclusion
CASE WHEN cast(icd9_code as int) in (
	3893,	--Venous cath NEC
	3897,	--CV cath plcmt w guidance
	8962	--Cvp monitoring
) then 1 else 0 END AS CVC,  	
CASE WHEN cast(icd9_code as int) in (
	3995,	--	Hemodialysis
	3895,	--	Ven cath renal dialysis
	3943	--	Remov ren dialysis shunt
) then 1 else 0 END AS dialysis,
CASE WHEN cast(icd9_code as int) in (
	8872	--	Dx ultrasound-heart
) then 1 else 0 END AS echo,
CASE WHEN cast(icd9_code as int) in (
	8964,	--	Pulmon art wedge monitor
	8963	--	Pulmon art press monitor
) then 1 else 0 END AS PAC,
CASE WHEN cast(icd9_code as int) in (
	17	--	Infusion of vasopressor
) then 1 else 0 END AS pressor,
CASE WHEN cast(icd9_code as int) in (
	3721,	--	Rt heart cardiac cath
	8852	--	Rt heart angiocardiogram
) then 1 else 0 END AS RHC,
CASE WHEN cast(icd9_code as int) in (
	3491	--	Thoracentesis
) then 1 else 0 END AS thora,
CASE WHEN cast(icd9_code as int) in (
	9604,	--	Insert endotracheal tube
	9671,	--	Cont inv mec ven <96 hrs
	9672,	--	Cont inv mec ven 96+ hrs
	9605,	--	Resp tract intubat NEC
	9670,	--	Con inv mec ven-unsp dur
	9390	--	Non-invasive mech vent
) then 1 else 0 END AS vent,
CASE WHEN cast(icd9_code as int) in (
	3615,	--1 int mam-cor art bypass
	8856,	--Coronar arteriogr-2 cath
	3722,	--	Left heart cardiac cath
	3723,	--	Rt/left heart card cath
	8853,	--	Lt heart angiocardiogram
	66,	--	PTCA
	3606,	--	Ins nondrug elut cor st
	3607,	--	Ins drug-elut coronry st
	8855,	--	Coronar arteriogr-1 cath
	8857,	--	Coronary arteriogram NEC
	8854,	--	Rt & lt heart angiocard
	24	--	IVUS coronary vessels
	) then 1 else 0 END AS toexclude,
0 as iabp, 0 as impella, 0 as port
from mimiciii.procedures_icd
)
, procedure_datetimeevents AS (
select subject_id, icustay_id, cast(itemid as int) as code, --, charttime, value, 
CASE WHEN itemid in (
	224288	--Arterial line Insertion Date
	,224287	--Arterial Line Dressing Change
	,224290	--Arterial line Tubing Change
	,224284	--Arterial line Cap Change
	,224285	--Arterial line Change over Wire Date
	) then 1 else 0 END AS ArterialLine, 		
 CASE WHEN itemid in (
	224280	--Multi Lumen Insertion Date
	,224279	--Multi Lumen Dressing Change
	,224261	--Multi Lumen Cap Change
	,224282	--Multi Lumen Tubing Change
	,224186	--PICC Line Dressing Change
	,224183	--PICC Line Cap Change
	,224184	--PICC Line Insertion Date
	,224187	--PICC Line Tubing Change
	,224296	--Cordis/Introducer Insertion Date
	,224295	--Cordis/Introducer Dressing Change
	,224298	--Cordis/Introducer Tubing Change
	,224292	--Cordis/Introducer Cap Change
	,224262	--Multi Lumen Change over Wire Date
	,224185	--PICC Line Change over Wire Date
	,225317	--Trauma Line Insertion Date
	,225216	--Trauma Line Dressing Change
	,225218	--Trauma Line Tubing Change
	,225213	--Trauma Line Cap Change
	,227724	--AVA Insertion Date
	,227729	--AVA Tubing Change
	,227720	--AVA Cap Change
	,225329	--Tunneled (Hickman) Dressing Change
	,227722	--AVA Dressing Change
	,225327	--Tunneled (Hickman) Cap Change
	,225332	--Tunneled (Hickman) Tubing Change
	,225386	--Presep Catheter Insertion Date
	,225385	--Presep Catheter Dressing Change
	,225383	--Presep Catheter Cap Change
	,225390	--Presep Catheter Tubing Change
	,225330	--Tunneled (Hickman) Insertion Date
	,224293	--Cordis/Introducer Change over Wire Date
	,225369	--Pheresis Catheter Dressing Change
	,225370	--Pheresis Catheter Insertion Date
	,225367	--Pheresis Catheter Cap Change
	,225372	--Pheresis Catheter Tubing Change
	,225394	--Triple Introducer Insertion Date
	,225393	--Triple Introducer Dressing Change
	,225396	--Triple Introducer Tubing Change
	,225391	--Triple Introducer Cap Change
	,225214	--Trauma Line Change over Wire Date
	,225368	--Pheresis Catheter Change over Wire Date
	,227721	--AVA Change over Wire Date
	,225328	--Tunneled (Hickman) Change over Wire Date
	,225392	--Triple Introducer Change over Wire Date
	) then 1 else 0 END AS CVC, 		
 CASE WHEN itemid in (
 	225321	--Dialysis Catheter Dressing Change
	,225322	--Dialysis Catheter Insertion Date
	,225318	--Dialysis Catheter Cap Change
	,225324	--Dialysis CatheterTubing Change
	,225319	--Dialysis Catheter Change over Wire Date
	,225128	--Last dialysis
	) then 1 else 0 END AS Dialysis, 		
 CASE WHEN itemid in (
 	225338	--IABP Insertion Date
	,225337	--IABP Dressing Change
	,225340	--IABP Tubing Change
	,225336	--IABP Change over Wire Date
	) then 1 else 0 END AS IABP, 		
 CASE WHEN itemid in (
 	228168	--Impella Insertion Date
	,228166	--Impella Dressing Change
	,228165	--Impella Daily Tubing Change
	,228160	--Impella Aortic Pressure Tubing Change
	) then 1 else 0 END AS Impella, 		
 CASE WHEN itemid in (
 	225354	--PA Catheter Insertion Date
	,225356	--PA Catheter Tubing Change
	,225353	--PA Catheter Dressing Change
	,225351	--PA Catheter Cap Change
	,225316	--CCO PAC Insertion Date
	,225224	--CCO PAC Dressing Change
	,225226	--CCO PAC Tubing Change
	,225221	--CCO PAC Cap Change
	,225352	--PA Catheter Change over Wire Date
	,225222	--CCO PAC Change over Wire Date
	,225384	--Presep Catheter Change over Wire Date
	,227542	--ScvO2 (Presep) Calibrated
	) then 1 else 0 END AS PAC, 		
 CASE WHEN itemid in (
 	227361	--Indwelling (PortaCath) Dressing Change
	,227126	--Indwelling (PortaCath) Port #1 Date Accessed
	,225380	--Indwelling Port (PortaCath)Tubing Change
	,225375	--Indwelling Port (PortaCath) Cap Change
	,225378	--Indwelling Port (PortaCath) Insertion Date
	,227197	--Indwelling (PortaCath) Port #2 Date Accessed
	,227198	--Indwelling (PortaCath) Port #1 Date De-accessed
	,227199	--Indwelling (PortaCath) Port #2 Date De-accessed
	) then 1 else 0 END AS Port,		
CASE WHEN itemid in (
 	225338	--IABP Insertion Date
	,225337	--IABP Dressing Change
	,225340	--IABP Tubing Change
	,225336	--IABP Change over Wire Date
 	,228168	--Impella Insertion Date
	,228166	--Impella Dressing Change
	,228165	--Impella Daily Tubing Change
	,228160	--Impella Aortic Pressure Tubing Change
	) then 1 else 0 END AS toexclude,
0 as bronch, 0 as cath, 0 as echo, 0 as pressor, 0 as rhc, 0 as thora, 0 as vent
from mimiciii.datetimeevents
)

, procedures_ as (
select * from procedure_datetimeevents
union all
select * from procedures_icd
union all 
select * from procedure_mv)

-- group by icustay_id, subject_id
select icustay_id, subject_id
    ,CASE when sum(arterialline) > 0 then 1 else 0 END AS arterialline
    ,CASE when sum(cvc) > 0 then 1 else 0 END AS cvc
    ,CASE WHEN sum(dialysis) > 0 then 1 else 0 END AS dialysis
    ,CASE WHEN sum(iabp) > 0 then 1 else 0 END AS iabp
    ,CASE WHEN sum(impella) > 0 then 1 else 0 END AS impella    
    ,CASE WHEN sum(pac) > 0 then 1 else 0 END AS pac
    ,CASE WHEN sum(port) > 0 then 1 else 0 END AS port   
    ,CASE WHEN sum(toexclude) > 0 then 1 else 0 END AS toexclude   
    ,CASE WHEN sum(bronch) > 0 then 1 else 0 END AS bronch
    ,CASE WHEN sum(cath) > 0 then 1 else 0 END AS cath  
    ,CASE WHEN sum(echo) > 0 then 1 else 0 END AS echo
    ,CASE WHEN sum(pressor) > 0 then 1 else 0 END AS pressor   
    ,CASE WHEN sum(rhc) > 0 then 1 else 0 END AS rhc   
    ,CASE WHEN sum(thora) > 0 then 1 else 0 END AS thora   
    ,CASE WHEN sum(vent) > 0 then 1 else 0 END AS vent  
from procedures_
group by subject_id, icustay_id
