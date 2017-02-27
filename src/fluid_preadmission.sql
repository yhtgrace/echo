set search_path to mimiciii;

DROP MATERIALIZED VIEW IF EXISTS fluid_preadmission CASCADE;

CREATE MATERIALIZED VIEW fluid_preadmission AS 

with mv as
(
select ie.icustay_id, sum(ie.amount) as sum
from mimiciii.inputevents_mv ie, mimiciii.d_items ci
where ie.itemid=ci.itemid and ie.itemid in (30054,30055,30101,30102,30103,30104,30105,30108,226361,226363,226364,226365,226367,226368,226369,226370,226371,226372,226375,226376,227070,227071,227072)
group by icustay_id
), cv as
(
select ie.icustay_id, sum(ie.amount) as sum
from mimiciii.inputevents_cv ie, mimiciii.d_items ci
where ie.itemid=ci.itemid and ie.itemid in (30054,30055,30101,30102,30103,30104,30105,30108,226361,226363,226364,226365,226367,226368,226369,226370,226371,226372,226375,226376,227070,227071,227072)
group by icustay_id
)
 
select pt.icustay_id,
case when mv.sum is not null then mv.sum
when cv.sum is not null then cv.sum
else null end as inputpreadm
from mimiciii.icustays pt
left outer join mv
on mv.icustay_id=pt.icustay_id
left outer join cv
on cv.icustay_id=pt.icustay_id
order by icustay_id
