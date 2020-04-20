/***
Requires: master_match
, crit_attribute_updated
, trial_attribute_updated
, trial_logic_levels
Results:
    master_patient_summary
*/
-- match adjusted with i/e and then mandatory
drop table if exists _ie_match cascade;
create table _ie_match as
select trial_id, person_id, attribute_id
, attribute_match
, ie_flag
, decode(ie_flag, True, attribute_match, not attribute_match) match_negated
, mandatory
, nvl(match_negated, not mandatory) as match_imputed
from master_match
join trial_attribute_updated using (trial_id, attribute_id)
;
/*
select * from _ie_match
order by person_id, trial_id, attribute_id
limit 100;

--summary of leaf nodes
drop view if exists _leaf_summary;
create view _leaf_summary as
with tmp as (
    select attribute_id, trial_id
    , sum(match_imputed::int) patients
    from _ie_match
    group by trial_id, attribute_id
) select *
from tmp join crit_attribute_updated using (attribute_id)
order by attribute_id
;

select * from _leaf_summary where trial_id='NCT03748641';
select * from trial_attribute_updated where trial_id='NCT03748641';
*/

-- collase the ie_match to levels of logic
-- summary of logic_l1 matches
drop view if exists _crit_l1 cascade;
create view _crit_l1 as
with _crit_l2 as (
    select trial_id, person_id, logic_l1, logic_l2
    , bool_and(match_imputed) l2_match
    from _ie_match
    join trial_logic_levels using (trial_id, attribute_id)
    group by trial_id, person_id, logic_l1, logic_l2
)
select trial_id, person_id, logic_l1
, bool_or(l2_match) l1_match
from _crit_l2
group by trial_id, person_id, logic_l1
;

create view logic_l1_summary as
select logic_l1, trial_id
, sum(l1_match::int) patients
from _crit_l1
group by trial_id, logic_l1
order by trial_id, logic_l1
;
/*
select distinct l1_match from _crit_l1;
select * from logic_l1_summary where trial_id='NCT03748641'
;
order by ie_flag desc, attribute_id;
select count(*), count(distinct logic_l1), count(distinct trial_id) from v_logic_l1_summary;
    -- different trial using a variety number of logic1s

with tmp as (
    select trial_id, person_id
    , bool_or(case when logic_l1='adt.or' then l1_match end) adt_match
    , bool_or(case when logic_l1='384' then l1_match end) testo_match
    , bool_or(case when logic_l1='sta.or' then l1_match end) sta_match
    , bool_or(case when logic_l1='397' then l1_match end) aa2_match
    from _crit_l1
    where trial_id='NCT03748641'
    group by trial_id, person_id
) 
select count(distinct person_id)
from tmp
--where adt_match and testo_match --502
--where adt_match and testo_match and sta_match --343
where adt_match and testo_match and aa2_match --285
;
*/

--drop view if exists trial_patient_count cascade;
drop view if exists trial_patient_count;
create view trial_patient_count as
with _crit_l0 as (
    select trial_id, person_id
    , bool_and(l1_match) patient_match
    from _crit_l1
    group by trial_id, person_id
)
select trial_id
, sum(patient_match::int) patients
from _crit_l0
group by trial_id
order by patients desc
;

drop view if exists master_patient_summary;
create view master_patient_summary as
with iec as (
    select trial_id, attribute_id
    , nvl(sum(attribute_match::int), 0) raw_count
    , sum(match_imputed::int) adjusted_count
    from _ie_match
    group by trial_id, attribute_id
)
select trial_id
, l0.patients as final_count
, l1.patients as l1_count, logic_l1
, adjusted_count, mandatory::int, ie_flag::int
, raw_count, attribute_id
, attribute_group || '>> ' || attribute_name || '>> ' || attribute_value || '>> ' || ie_value as attribute_title
from trial_patient_count l0
join logic_l1_summary l1 using (trial_id)
    join trial_logic_levels using (trial_id, logic_l1)
join iec using (trial_id, attribute_id)
join trial_attribute_updated using (trial_id, attribute_id)
join crit_attribute_updated using (attribute_id)
order by final_count desc, trial_id, ie_flag desc, logic_l1, attribute_id
;
/*
select * from master_patient_summary where trial_id='NCT03748641';
cd $working_dir
select_from_db_schema_table.py ${db_conn} ${working_schema}.master_patient_summary > \
    master_patient_summary_$(today_stamp).csv
select
*/
