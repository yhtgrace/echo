-- Table: mimiciii.echo_annotations

DROP TABLE IF EXISTS mimiciii.echo_annotations_unique CASCADE;

CREATE TABLE mimiciii.echo_annotations_unique
(
  -- row_id serial primary key,
  subject_id integer NOT NULL,
  hadm_id integer,
  key integer,
  new_time timestamp(0) without time zone,
  height integer,
  weight integer,
  sys integer,
  diastolic integer,
  hr integer,
  TV_pulm_htn integer,
  TV_regurgitation integer,	
  TV_stenosis integer,	
  LV_cavity integer,
  LV_diastolic integer,
  LV_systolic integer,
  LV_wall	integer,
  RV_cavity integer,
  RV_volume_overload integer,
  RV_systolic integer,
  RV_wall integer,
  AV_regurgitation integer,
  AV_stenosis integer,
  MV_regurgitation integer,
  MV_stenosis integer,
  LA_cavity integer,
  RA_dilated integer,
  RA_pressure integer
)
WITH (
  OIDS=FALSE
);
--ALTER TABLE mimiciii.echo_annnotations_unique
--  OWNER TO postgres;
COPY mimiciii.echo_annotations_unique FROM '/Users/yhtgrace/Documents/projects/echo/teemo/resources/echo_annotations_March2017/echo_2017-03-03-13-03-46-354000_modified.txt' CSV HEADER;
--COPY mimiciii.echo_annotations_unique FROM 'C:\Users\310050083\Documents\echo\resources\echo_2017-02-02-13-03-46=354000_modified.csv' CSV HEADER;
