DROP MATERIALIZED VIEW IF EXISTS d_prescriptions CASCADE;

CREATE MATERIALIZED VIEW d_prescriptions AS

SELECT DISTINCT ps.drug_type
    ,ps.drug
    ,ps.drug_name_poe
    ,ps.drug_name_generic
    ,ps.formulary_drug_cd
    ,ps.gsn
    ,ps.ndc
    ,ps.route
FROM prescriptions ps;

