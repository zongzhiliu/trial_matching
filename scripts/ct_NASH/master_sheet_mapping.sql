/* !! do not run
Result: v_master_sheet_new
*/
-- clean up crit_attribute: removing attributes notimplemented, not used in trials
drop table if exists crit_attribute_used;
create table crit_attribute_used as
select attribute_id
, btrim(attribute_group) attribute_group
, btrim(attribute_name) attribute_name
, btrim(attribute_value) attribute_value
, btrim(mandatory_default) ilike 'y' as mandatory_default
, logic, code_type, ie_values
from crit_attribute_raw
where code_type is not null
;

-- filter trial attribute used renew
alter table trial_attribute_used rename to trial_attribute_used_raw;
create table trial_attribute_used as
select attribute_id, trial_id
, inclusion, exclusion
, inclusion is NULL as ie
, btrim(nvl(inclusion, exclusion)) ie_value
from trial_attribute_used_raw
join crit_attribute_used using (attribute_id)
;

-- make sure each trial have same attributes for all patients
-- alter table cohort rename to cohort_raw;
-- create table cohort as
-- select c.*, mrn person_id
-- from cohort_raw c;
create table cohort as
select mrn, mrn person_id
from demo;

drop table if exists _master_sheet_new;
create temporary table _master_sheet_new as
select attribute_id, trial_id, person_id
, tap.inclusion, tap.exclusion
, attribute_match
from (trial_attribute_used cross join cohort) tap
left join v_master_sheet using (attribute_id, trial_id, person_id)
;


------------------------------------------------------------
-- new crit_attribute
-- expand logic
drop table if exists _attr_logic;
create temporary table _attr_logic as
with tmp as (
    select attribute_id
    , split_part(logic, '/', 1) p1
    , split_part(logic, '/', 2) p2
    from crit_attribute_used
)
select attribute_id
, case when nvl(p1, '')=''
    then attribute_id::varchar
    else p1
    end logic_l1
, case when nvl(p2, '')=''
    then attribute_id::varchar
    else p2
    end logic_l2
from tmp
;

-- _attr_value
drop table if exists _attr_value;
create temporary table _attr_value as
select distinct attribute_id, ie_value
from trial_attribute_used
;

-- 4) crit_attribute_used_new, v_crit_attribute_used_new
drop table if exists crit_attribute_used_new cascade;
create table crit_attribute_used_new as
select row_number() over (order by attribute_id, ie_value) as new_attribute_id
, attribute_id as old_attribute_id
, attribute_group
, case when lower(attribute_value) ~ '^(min|max)'
    then attribute_name || ': ' || attribute_value
    else attribute_name
    end as attribute_name
, case when lower(attribute_value) ~ '^(min|max)'
    then ie_value
    else attribute_value
    end as attribute_value
, ie_value
, mandatory_default, logic_l1, logic_l2
from _attr_value
join _attr_logic using (attribute_id)
join crit_attribute_used using (attribute_id)
order by new_attribute_id;

drop view if exists v_crit_attribute_used_new;
create view v_crit_attribute_used_new as
select new_attribute_id, old_attribute_id
, attribute_group, attribute_name, attribute_value
, mandatory_default::int as mandatory_default
, logic_l1, logic_l2
from crit_attribute_used_new
order by new_attribute_id
;
/*
cd $working_dir
select_from_db_schema_table.py rdmsdw ${working_schema}.v_crit_attribute_used_new \
    > v_crit_attribute_used_new_$(today_stamp).csv

select count(distinct attribute_id) from crit_attribute_used;
select count(*), count(distinct old_attribute_id) from crit_attribute_used_new;
select * from v_crit_attribute_used_new where logic_l1='moa.or';
*/

-- 5) v_master_sheet_new: implement the logic and mandatory
drop table if exists master_sheet_new;
create table master_sheet_new as
with _ms as (
    select m.*
    , attribute_id as old_attribute_id
    , btrim(nvl(inclusion, exclusion)) ie_value
    from _master_sheet_new m
)
select new_attribute_id, old_attribute_id
, trial_id, person_id
, attribute_match
, inclusion is not null as inclusion
, exclusion is not null as exclusion
, mandatory_default mandatory
, ie_value
from _ms
join crit_attribute_used_new using (old_attribute_id, ie_value)
;
/*
select count(*) from _master_sheet_new;
select count(*) from v_master_sheet;
*/

drop view if exists v_master_sheet_new;
create view v_master_sheet_new as
select new_attribute_id, old_attribute_id
, trial_id, person_id
, attribute_group, attribute_name, attribute_value --from cn
, attribute_match::int
, inclusion::int, exclusion::int
, m.mandatory::int
, logic_l1, logic_l2 -- from cn
from master_sheet_new m
join v_crit_attribute_used_new cn using (new_attribute_id, old_attribute_id)
order by person_id, trial_id, new_attribute_id
;

-- for faster loading

drop view if exists v_master_sheet_n;
create view v_master_sheet_n as
select new_attribute_id
, trial_id, person_id
, attribute_match
, inclusion, exclusion
, mandatory
from v_master_sheet_new
;

/*
-- same number of records with old master sheet
select count(*) from v_master_sheet;
select count(*) from _master_sheet_new;

-- each trial have same number of attrs for each patient
select trial_id, person_id, count(*)
from v_master_sheet_new
where person_id::varchar like '%000'
group by trial_id, person_id
order by trial_id, person_id
limit 99
;
*/
