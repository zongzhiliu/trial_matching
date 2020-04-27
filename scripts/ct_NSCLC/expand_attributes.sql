/*
Results: crit_attribute_expanded
, master_sheet_expanded
Requires: master_match
, crit_attribute_updated
, trial_attribute_updated
, trial_logic_levels
*/
drop table if exists _attr_value cascade;
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

create or replace view qc_attribute_match_summary as
with av as (
    select new_attribute_id, attribute_match
    , count(distinct person_id) patients
    from v_master_sheet_expanded
    group by new_attribute_id, attribute_match
), pivot as (
    select new_attribute_id
    , nvl(sum(case when attribute_match is True then patients end), 0) patients_true
    , nvl(sum(case when attribute_match is False then patients end), 0) patients_false
    , nvl(sum(case when attribute_match is Null then patients end), 0) patients_null
    from av group by new_attribute_id
)
select new_attribute_id, attribute_id
, patients_true, patients_false, patients_null
, attribute_group+'| '+attribute_name+'| '+attribute_value as attribute_title
from pivot join v_crit_attribute_expanded using (new_attribute_id)
order by regexp_substr(attribute_id, '[0-9]+')::int, new_attribute_id
;
