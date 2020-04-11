/*
Results: crit_attribute_used_new
, master_sheet_new
*/
drop table _attr_value;
create table _attr_value as
select distinct attribute_id
, attribute_group, attribute_name
, attribute_value, ie_value
from trial_attribute_updated
join crit_attribute_updated using (attribute_id)
;
/*
select_from_db_schema_table.py rimsdw -q "select * from $working_schema._attr_value order by attribute_id, ie_value"  > ${working_dir}/_attr_value.csv
*/

drop table crit_attribute_used_new cascade;
create table crit_attribute_used_new as
select row_number() over (order by attribute_id, attribute_value, ie_value) as new_attribute_id
, attribute_id
, attribute_group
, case when lower(attribute_value) ~ '^(min|max|primary gs|secondary gs)' then
        attribute_name || ': ' || attribute_value
    else attribute_name
    end as attribute_name
, case when lower(attribute_value) ~ '^(min|max|primary gs|secondary gs)' then
        ie_value
    else attribute_value
    end as attribute_value
, mandatory_default
, logic_default
, ie_value
from _attr_value
join crit_attribute_updated cn using (attribute_id, attribute_group, attribute_name, attribute_value)
order by new_attribute_id;

/*
select_from_db_schema_table.py rimsdw -q "select * from $working_schema.crit_attribute_used_new order by new_attribute_id"  > ${working_dir}/crit_attribute_used_new_.csv
*/
drop view if exists master_sheet_new cascade;
create view master_sheet_new as
select new_attribute_id, attribute_id
, trial_id, person_id
, attribute_group, attribute_name, attribute_value
, ie_value
, attribute_match
, ie_flag, mandatory, logic_l1 --, logic_l2
from master_match mm
join trial_attribute_w_levels ta using (trial_id, attribute_id) -- only one
join crit_attribute_used_new ca using (attribute_id, ie_value)
order by person_id, trial_id, new_attribute_id
;

-- to deliver
drop view v_crit_attribute_used_new cascade;
create view v_crit_attribute_used_new as
select new_attribute_id, attribute_id
, attribute_group, attribute_name, attribute_value
, ie_value, mandatory_default, logic_default
from crit_attribute_used_new
order by new_attribute_id;

-- to deliver
drop view if exists v_master_sheet_new cascade;
create view v_master_sheet_new as
select new_attribute_id, attribute_id
, trial_id, person_id+3040 person_id
, attribute_group, attribute_name, attribute_value
, ie_value, attribute_match::int
, ie_flag::int inclusion
, (not ie_flag)::int exclusion
, mandatory::int
, logic_l1 --, logic_l2
from master_sheet_new
;
/*
select count(*) from master_sheet_new;
select * from master_sheet_new limit 99;
select count(*), count(distinct person_id), count(distinct attribute_id), count(distinct trial_id)
from master_match;
select count(*), count(distinct person_id), count(distinct attribute_id), count(distinct trial_id)
from master_sheet;
select count(*), count(distinct person_id), count(distinct attribute_id), count(distinct trial_id)
from master_sheet_new;
select attribute_id, trial_id, person_id, count(*)
from master_match
group by attribute_id, trial_id, person_id
order by count(*) desc limit 99;
select count(*) from trial_attribute_updated;
    --3337
select count(distinct trial_id::varchar||attribute_id::varchar) from trial_attribute_updated;

select count(*) from (select distinct * from trial_attribute_updated)
select count(*) from (select distinct trial_id, attribute_id from trial_attribute_updated);
    --3310
;

select count(*) from _master_sheet_new;

-- 5) v_master_sheet_new
drop table if exists _ms;
create temporary table _ms as (
    select attribute_id as old_attribute_id
    , trial_id, person_id
    , cn.attribute_group, cn.attribute_name, cn.attribute_value
    , inclusion, exclusion, attribute_match
    , ie_value
    from _master_match
    join _crit_attribute_used_new cn using (attribute_id)
);

drop table _master_sheet_new cascade;
create table _master_sheet_new as
select new_attribute_id, old_attribute_id
, trial_id, person_id
, cn.attribute_group
, cn.new_attribute_name as attribute_name
, cn.new_attribute_value as attribute_value
, attribute_match
, inclusion is not null as inclusion
, exclusion is not null as exclusion
, case mandatory_default
    when 'yes' then True
    when 'no' then False
    end as mandatory
, logic_l1_id
from _ms
join crit_attribute_used_new cn using (old_attribute_id, ie_value)
;

