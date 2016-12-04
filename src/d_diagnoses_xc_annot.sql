-- load annotated exclusion diagnoses table
-- the only necessary columns are icd9_code and exclude
-- is there a more elegant way than redefining the table
DROP TABLE IF EXISTS d_diagnoses_xc_annot CASCADE; 
CREATE TABLE d_diagnoses_xc_annot 
(   icd9_code character varying(10), 
    short_title character varying(50), 
    long_title character varying(255), 
    k_card integer,
    k_heart integer,
    k_hemorrhag integer,
    k_bleed integer,
    k_embolism integer,
    k_shock integer,
    k_clot integer,
    num bigint,
    exclude integer, 
    comments character varying(50)
);

-- set path to csv
COPY d_diagnoses_xc_annot FROM '/Users/yhtgrace/Documents/projects/echo/teemo/resources/d_diagnoses_xc_annot.csv' CSV HEADER;
