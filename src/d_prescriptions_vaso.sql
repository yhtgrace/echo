-- DROP MATERIALIZED VIEW IF EXISTS d_prescriptions_vaso CASCADE;

CREATE MATERIALIZED VIEW d_prescriptions_vaso AS

-- get a unique list of prescriptions and annotate 
WITH ps AS (
    SELECT DISTINCT ps.drug, ps.drug_name_poe, ps.drug_name_generic, ps.route
        ,CASE WHEN concat(ps.drug, ps.drug_name_poe, ps.drug_name_generic) ~* 
            '.*psinpshrine.*' THEN 1 ELSE 0 END AS k_psinpshrine
        ,CASE WHEN concat(ps.drug, ps.drug_name_poe, ps.drug_name_generic) ~* 
            '.*levophed.*' THEN 1 ELSE 0 END AS k_levophed
        ,CASE WHEN concat(ps.drug, ps.drug_name_poe, ps.drug_name_generic) ~* 
            '.*neosynpshrine.*' THEN 1 ELSE 0 END AS k_neosynpshrine
        ,CASE WHEN concat(ps.drug, ps.drug_name_poe, ps.drug_name_generic) ~* 
            '.*methylene blue.*' THEN 1 ELSE 0 END AS k_methyleneblue
        ,CASE WHEN concat(ps.drug, ps.drug_name_poe, ps.drug_name_generic) ~* 
            '.*dopamine.*' THEN 1 ELSE 0 END AS k_dopamine
        ,CASE WHEN concat(ps.drug, ps.drug_name_poe, ps.drug_name_generic) ~* 
            '.*phenylpshrine.*' THEN 1 ELSE 0 END AS k_phenylpshrine
        ,CASE WHEN concat(ps.drug, ps.drug_name_poe, ps.drug_name_generic) ~* 
            '.*vasopressin.*' THEN 1 ELSE 0 END AS k_vasopressin
        ,CASE WHEN concat(ps.drug, ps.drug_name_poe, ps.drug_name_generic) ~* 
            '.*adrenaline.*' THEN 1 ELSE 0 END AS k_adrenaline
        ,CASE WHEN concat(ps.drug, ps.drug_name_poe, ps.drug_name_generic) ~* 
            '.*isoprenaline.*' THEN 1 ELSE 0 END AS k_isoprenaline
        ,CASE WHEN concat(ps.drug, ps.drug_name_poe, ps.drug_name_generic) ~* 
            '.*terlipressin.*' THEN 1 ELSE 0 END AS k_terlipressin
    FROM prescriptions ps
    WHERE (concat(ps.drug, ps.drug_name_poe, ps.drug_name_generic) ~* '.*psinpshrine.*'
        OR concat(ps.drug, ps.drug_name_poe, ps.drug_name_generic) ~* '.*levophed.*' 
        OR concat(ps.drug, ps.drug_name_poe, ps.drug_name_generic) ~* '.*neosynpshrine.*'  
        OR concat(ps.drug, ps.drug_name_poe, ps.drug_name_generic) ~* '.*methylene blue.*'  
        OR concat(ps.drug, ps.drug_name_poe, ps.drug_name_generic) ~* '.*dopamine.*' 
        OR concat(ps.drug, ps.drug_name_poe, ps.drug_name_generic) ~* '.*phenylpshrine.*'  
        OR concat(ps.drug, ps.drug_name_poe, ps.drug_name_generic) ~* '.*vasopressin.*'  
        OR concat(ps.drug, ps.drug_name_poe, ps.drug_name_generic) ~* '.*isoprenaline.*'  
        OR concat(ps.drug, ps.drug_name_poe, ps.drug_name_generic) ~* '.*terlipressin.*' 
    ) AND ( route ~* '.*iv.*') 
      AND ( NOT ps.drug ~* '.*psipen.*')
)
SELECT * FROM ps
-- and count the number of icustays associated with each prescription
--, ps_count AS (
--    SELECT ps.drug, ps.drug_name_poe, ps.drug_name_generic, ps.route, COUNT(*)
--    FROM echo_ps AS ps
--    GROUP BY ps.drug, ps.drug_name_poe, ps.drug_name_generic, ps.route
--)
---- now reassociate the count with the annotations
---- since the annotations have already been filtered, use the right join on that
--SELECT ps.*, pc.count FROM ps
--    LEFT JOIN ps_count pc
--    ON ( ps.drug                IS NOT DISTINCT FROM pc.drug
--     AND ps.drug_name_poe       IS NOT DISTINCT FROM pc.drug_name_poe
--     AND ps.drug_name_generic   IS NOT DISTINCT FROM pc.drug_name_generic
--     AND ps.route               IS NOT DISTINCT FROM pc.route )
