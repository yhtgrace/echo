set search_path to mimiciii;

-- DROP MATERIALIZED VIEW IF EXISTS chronic_dialysis CASCADE; 

CREATE MATERIALIZED VIEW chronic_dialysis AS  

SELECT subject_id, hadm_id, seq_num, icd9_code
  FROM mimiciii.diagnoses_icd
  where icd9_code in (
	 '5855' -- Chron kidney dis stage V
	,'5856' -- End stage renal disease
	, '40301' -- "Mal hyp kid w cr kid V"
	, '40311' -- "Ben hyp kid w cr kid V"
	, '40391' -- "Hyp kid NOS w cr kid V"
	, '40402' -- Mal hy ht/kd st V w/o hf"
	, '40403' -- Mal hyp ht/kd stg V w hf"
	, '40412' -- Ben hy ht/kd st V w/o hf"
	, '40413' -- Ben hyp ht/kd stg V w hf"
	, '40492' -- Hy ht/kd NOS st V w/o hf"
	, '40493' -- Hyp ht/kd NOS st V w hf
	)
  order by subject_id

	
