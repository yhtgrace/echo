-- write a table in csv format to stdout
COPY (SELECT * FROM d_prescriptions_vaso) TO STDOUT WITH CSV HEADER
--COPY (SELECT DISTINCT route FROM prescriptions) TO STDOUT WITH CSV HEADER
