DROP MATERIALIZED VIEW IF EXISTS combine_echo_filter_vars CASCADE;

CREATE MATERIALIZED VIEW combine_echo_filter_vars AS

select em.*, eg.intime_to_echo, eg.echo_to_outtime, eg.ps_vaso, eg.diag_xc, eg.age_at_intime, 
       eg.after_rowid, eg.before_rowid, eg.op_to_icu, eg.icu_to_op, eg.time_filter, 
       eg.age_filter
  from echo_filter_vars as eg
  left join echo_filter_vars_mx as em
  --on egrace.icustay_id = emx.icustay_id and egrace.charttime = emx.charttime and 
  on eg.row_id = em.row_id