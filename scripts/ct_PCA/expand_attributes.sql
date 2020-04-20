/*
Results: crit_attribute_expanded
, master_sheet_expanded
Requires: master_match
, crit_attribute_updated
, trial_attribute_updated
, trial_logic_levels
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

drop table if exists crit_attribute_expanded cascade;
create table crit_attribute_expanded as
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
drop view if exists master_sheet_expanded cascade;
create view master_sheet_expanded as
select new_attribute_id, attribute_id
, trial_id, person_id
, attribute_group, attribute_name, attribute_value
, ie_value
, attribute_match
, ie_flag, mandatory, logic_l1 --, logic_l2
from master_match mm
join trial_attribute_updated ta using (trial_id, attribute_id)
join trial_logic_levels using (trial_id, attribute_id)
join crit_attribute_expanded ca using (attribute_id, ie_value)
order by person_id, trial_id, new_attribute_id
;

-- to deliver
drop view if exists v_crit_attribute_expanded cascade;
create view v_crit_attribute_expanded as
select new_attribute_id, attribute_id
, attribute_group, attribute_name, attribute_value
, ie_value, mandatory_default, logic_default
from crit_attribute_expanded
order by new_attribute_id;

-- to deliver
drop view if exists v_master_sheet_expanded cascade;
create view v_master_sheet_expanded as
select new_attribute_id, attribute_id
, trial_id, person_id+3040 person_id
, attribute_group, attribute_name, attribute_value
, ie_value, attribute_match::int
, ie_flag::int inclusion
, (not ie_flag)::int exclusion
, mandatory::int
, logic_l1 --, logic_l2
from master_sheet_expanded
;

with tmp as (
select distinct new_attribute_id, attribute_id, attribute_name, inclusion, logic_l1 
from v_master_sheet_expanded where lower(attribute_name)~'adt'
)
select ct.assert (bool_or(inclusion=1 and logic_l1='adt.or'), 'adt.or if inclusion')
, ct.assert (bool_or(inclusion=0 and logic_l1~'39[345]'), 'adt.and if exclusion')
from tmp;

