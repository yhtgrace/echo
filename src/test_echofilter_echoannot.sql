set search_path to mimiciii;

DROP MATERIALIZED VIEW IF EXISTS test_echo_fluid CASCADE;

CREATE MATERIALIZED VIEW test_echo_fluid AS

select ef.*, fl.daily_input_ml, fl.daily_output_ml, fl.daily_balance_ml
from echo_filtered_mx as ef
join fluid_dailybalance as fl
on ef.subject_id  = fl.subject_id and cast(ef.charttime as date) = fl.chartdate