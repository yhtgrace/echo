-- Table: mimiciii.echo_annotations

-- DROP TABLE mimiciii.echo_annotations;

CREATE TABLE mimiciii.echo_annotations
(
  subject_id integer NOT NULL,
  hadm_id integer NOT NULL,
  age double precision,
  gender character varying(5) NOT NULL,
  new_time timestamp(0) without time zone,
  icustay_id integer NOT NULL,
  first_careunit character varying(5) NOT NULL,
  intime timestamp(0) without time zone,
  outtime timestamp(0) without time zone,
  pulmhtn integer NOT NULL,
  dm integer NOT NULL,
  esrd integer NOT NULL,
  isdead integer NOT NULL,
  age_of_death double precision,
  days_after_icu_admit_death double precision,
  days_after_discharge_death double precision,
  status character varying(10) NOT NULL,
  TV_pulm_htn integer,
  TV_TR integer,
  LV_cavity integer,
  LV_diastolic integer,
  LV_systolic integer,
  LV_wall integer,
  RV_cavity integer,
  RV_diastolic_fluid integer,	
  RV_systolic integer,	
  RV_wall integer
)
WITH (
  OIDS=FALSE
);
ALTER TABLE mimiciii.echo_annotations
  OWNER TO postgres;
