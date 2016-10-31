DROP MATERIALIZED VIEW d_prescriptions_vaso CASCADE;

CREATE MATERIALIZED VIEW d_prescriptions_vaso AS

-- select only entries where the icustay id matches those in echo icustays
-- since we only care about the number of echos associated with each drug
-- drop duplicates since we do not care if the same drug was administered 
-- more than once during an icustay
-- note that each prescription is defined as (drug, drug_name_poe, drug_name_generic, route)
WITH echo_ps AS (
    SELECT DISTINCT ps.icustay_id, ps.drug, ps.drug_name_poe, ps.drug_name_generic, ps.route 
    FROM prescriptions ps
    INNER JOIN echo_icustay ei
        ON ei.icustay_id = ps.icustay_id
) 
-- get a unique list of prescriptions and annotate 
, ps AS (
    SELECT DISTINCT ep.drug, ep.drug_name_poe, ep.drug_name_generic, ep.route
        ,CASE WHEN concat(ep.drug, ep.drug_name_poe, ep.drug_name_generic) ~* 
            '.*epinephrine.*' THEN 1 ELSE 0 END AS k_epinephrine
        ,CASE WHEN concat(ep.drug, ep.drug_name_poe, ep.drug_name_generic) ~* 
            '.*levophed.*' THEN 1 ELSE 0 END AS k_levophed
        ,CASE WHEN concat(ep.drug, ep.drug_name_poe, ep.drug_name_generic) ~* 
            '.*neosynephrine.*' THEN 1 ELSE 0 END AS k_neosynephrine
        ,CASE WHEN concat(ep.drug, ep.drug_name_poe, ep.drug_name_generic) ~* 
            '.*methylene blue.*' THEN 1 ELSE 0 END AS k_methyleneblue
        ,CASE WHEN concat(ep.drug, ep.drug_name_poe, ep.drug_name_generic) ~* 
            '.*dopamine.*' THEN 1 ELSE 0 END AS k_dopamine
        ,CASE WHEN concat(ep.drug, ep.drug_name_poe, ep.drug_name_generic) ~* 
            '.*phenylephrine.*' THEN 1 ELSE 0 END AS k_phenylephrine
        ,CASE WHEN concat(ep.drug, ep.drug_name_poe, ep.drug_name_generic) ~* 
            '.*vasopressin.*' THEN 1 ELSE 0 END AS k_vasopressin
        ,CASE WHEN concat(ep.drug, ep.drug_name_poe, ep.drug_name_generic) ~* 
            '.*adrenaline.*' THEN 1 ELSE 0 END AS k_adrenaline
        ,CASE WHEN concat(ep.drug, ep.drug_name_poe, ep.drug_name_generic) ~* 
            '.*isoprenaline.*' THEN 1 ELSE 0 END AS k_isoprenaline
        ,CASE WHEN concat(ep.drug, ep.drug_name_poe, ep.drug_name_generic) ~* 
            '.*terlipressin.*' THEN 1 ELSE 0 END AS k_terlipressin
    FROM echo_ps ep
    WHERE (concat(ep.drug, ep.drug_name_poe, ep.drug_name_generic) ~* '.*epinephrine.*'
        OR concat(ep.drug, ep.drug_name_poe, ep.drug_name_generic) ~* '.*levophed.*' 
        OR concat(ep.drug, ep.drug_name_poe, ep.drug_name_generic) ~* '.*neosynephrine.*'  
        OR concat(ep.drug, ep.drug_name_poe, ep.drug_name_generic) ~* '.*methylene blue.*'  
        OR concat(ep.drug, ep.drug_name_poe, ep.drug_name_generic) ~* '.*dopamine.*' 
        OR concat(ep.drug, ep.drug_name_poe, ep.drug_name_generic) ~* '.*phenylephrine.*'  
        OR concat(ep.drug, ep.drug_name_poe, ep.drug_name_generic) ~* '.*vasopressin.*'  
        OR concat(ep.drug, ep.drug_name_poe, ep.drug_name_generic) ~* '.*isoprenaline.*'  
        OR concat(ep.drug, ep.drug_name_poe, ep.drug_name_generic) ~* '.*terlipressin.*' 
    ) AND route ~* '.*iv.*'
)
-- and count the number of icustays associated with each prescription
, ps_count AS (
    SELECT ep.drug, ep.drug_name_poe, ep.drug_name_generic, ep.route, COUNT(*)
    FROM echo_ps AS ep
    GROUP BY ep.drug, ep.drug_name_poe, ep.drug_name_generic, ep.route
)
-- now reassociate the count with the annotations
-- since the annotations have already been filtered, use the right join on that
SELECT ps.*, pc.count FROM ps
    LEFT JOIN ps_count pc
    ON ( ps.drug                IS NOT DISTINCT FROM pc.drug
     AND ps.drug_name_poe       IS NOT DISTINCT FROM pc.drug_name_poe
     AND ps.drug_name_generic   IS NOT DISTINCT FROM pc.drug_name_generic
     AND ps.route               IS NOT DISTINCT FROM pc.route )
