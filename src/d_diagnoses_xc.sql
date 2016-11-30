-- exclusion criteria: no cardiogenic shock, STEMI, PE, or hemorrhagic shock
-- pull out all diagnoses with the keywords (card, heart, hemorrhag, bleed, embolism)
-- and filter for those diagnoses associated with echos  
DROP MATERIALIZED VIEW IF EXISTS d_diagnoses_xc CASCADE;

CREATE MATERIALIZED VIEW d_diagnoses_xc AS

WITH di AS (
    -- select diagnoses for all hadm_ids in echo_icustay
    SELECT ei.icustay_id, di.*
    FROM diagnoses_icd di
    RIGHT JOIN echo_icustay ei -- keep only hadm_ids from echo_icustay
        ON di.hadm_id = ei.hadm_id
),
eid AS (
    -- filter diagnoses for keywords
    SELECT di.icustay_id, did.*
        ,CASE WHEN did.long_title ~* '.*card.*' THEN 1 ELSE 0 END AS k_card
        ,CASE WHEN did.long_title ~* '.*heart.*' THEN 1 ELSE 0 END  AS k_heart
        ,CASE WHEN did.long_title ~* '.*hemorrhag.*' THEN 1 ELSE 0 END AS k_hemorrhag
        ,CASE WHEN did.long_title ~* '.*bleed.*' THEN 1 ELSE 0 END AS k_bleed
        ,CASE WHEN did.long_title ~* '.*embolism.*' THEN 1 ELSE 0 END AS k_embolism
        ,CASE WHEN did.long_title ~* '.*shock.*' THEN 1 ELSE 0 END AS k_shock
        ,CASE WHEN did.long_title ~* '.*clot.*' THEN 1 ELSE 0 END AS k_clot
    FROM d_icd_diagnoses did
    RIGHT JOIN di
        ON did.icd9_code = di.icd9_code
    WHERE
           did.long_title ~* '.*card.*'
        OR did.long_title ~* '.*heart.*'
        OR did.long_title ~* '.*hemorrhag.*'
        OR did.long_title ~* '.*bleed.*'
        OR did.long_title ~* '.*embolism.*'
        OR did.long_title ~* '.*shock.*'
        OR did.long_title ~* '.*clot.*'
),
eidc AS (
    SELECT icd9_code 
       ,COUNT(icd9_code) AS num
    FROM eid
    GROUP BY icd9_code
)
SELECT DISTINCT ON(eid.icd9_code)
     eid.icd9_code, eid.short_title, eid.long_title
    ,eid.k_card, eid.k_heart, eid.k_hemorrhag, eid.k_bleed, eid.k_embolism
    ,eid.k_shock, eid.k_clot
    ,eidc.num 
FROM eid
INNER JOIN eidc
    ON eid.icd9_code = eidc.icd9_code
