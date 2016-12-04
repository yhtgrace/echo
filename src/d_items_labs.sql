DROP MATERIALIZED VIEW IF EXISTS d_items_labs CASCADE;

CREATE MATERIALIZED VIEW d_items_labs AS

SELECT * FROM d_items 
WHERE (
       label ~* '.*ph.*'
    OR label ~* '.*albumin.*'
    OR label ~* '.*bicarbonate.*'
    OR label ~* '.*c-reactive.*'
    OR label ~* '.*sedimentation rate.*'
    OR label ~* '.*creatinine.*'
    OR label ~* '.*ck-mb index.*'
    OR label ~* '.*cpk.*'
    OR label ~* '.*ckmb.*'
    OR label ~* '.*ck-mb.*'
    OR label ~* '.*gfr.*'
    OR label ~* '.*esr.*'
    OR label ~* '.*tnt.*'
    OR label ~* '.*tni.*'
    OR label ~* '.*trop.*'
    OR label ~* '.*wbc.*'
    OR label ~* '.*leukocyte.*'
    OR label ~* '.*white blood cells.*'
    OR label ~* '.*hematocrit.*'
    OR label ~* '.*hct.*'
    OR label ~* '.*hemoglobin.*'
    OR label ~* '.*hb.*'
    OR label ~* '.*hgb.*'
    OR label ~* '.*lactate.*'
    OR label ~* '.*bnp.*'
    OR label ~* '.*natriuretic.*'
)

