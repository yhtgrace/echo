-- write a table in csv format to stdout
--COPY (SELECT * FROM d_labs_all) TO STDOUT WITH CSV HEADER
--COPY (SELECT DISTINCT category FROM d_items) TO STDOUT WITH CSV HEADER
