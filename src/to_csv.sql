-- write a table in csv format to stdout
COPY (SELECT * FROM icu_features) TO STDOUT WITH CSV HEADER
--COPY (SELECT DISTINCT route FROM prescriptions) TO STDOUT WITH CSV HEADER
