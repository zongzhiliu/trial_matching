set search_path=ct_mm;
-- 1). modify the mandited column
/*
crit_attribute_mapping_raw
load_into_db_schema_some_csvs.py rimsdw ct_mm crit_attribute_mapping_raw.csv -d
*/

-- 2). _crit_attriburte_used_new
drop table if exists _crit_attribute_used_new;
create table _crit_attribute_used_new as (
select attribute_id
, new_attribute_group as attribute_group
, nvl(new_attribute_name, '_') as attribute_name
, new_attribute_value as attribute_value
, cam.mandated as mandatory_default
, nvl(cau.logic, attribute_id||'.or') as logic_l1_id
from v_crit_attribute_used cau
join crit_attribute_mapping_raw cam using (attribute_id)
);
/*
select count(*), count(distinct attribute_id) from v_crit_attribute_used;
select count(*), count(distinct attribute_id) from _crit_attribute_used_new;
select * from _crit_attribute_used_new;
*/

-- 3) _attr_value
drop table _ms;
create temporary table _ms as (
    select attribute_id as old_attribute_id
    , trial_id, person_id
    , cn.attribute_group, cn.attribute_name, cn.attribute_value
    , inclusion, exclusion, attribute_match
    , nvl(inclusion, exclusion) _ie_value
    , _ie_value as ie_value
    --, case when _ie_value like 'yes%' then 'yes' else _ie_value
    --    end as ie_value -- convert yes <4W to yes
    from v_master_sheet
    join _crit_attribute_used_new cn using (attribute_id)
);

drop table _attr_value;
create table _attr_value as
select distinct old_attribute_id as attribute_id
, attribute_group, attribute_name, attribute_value
, ie_value
from _ms
;
/*
select_from_db_schema_table.py rimsdw -q 'select * from ct_mm._attr_value order by attribute_id, ie_value'  > _attr_value.csv
-- only min/max need to be dealed
*/
-- 4) crit_attribute_used_new, v_crit_attribute_used_new
drop table crit_attribute_used_new cascade;
create table crit_attribute_used_new as
select row_number() over (order by attribute_id, attribute_value, ie_value) as new_attribute_id
, attribute_id as old_attribute_id
, mandatory_default, logic_l1_id
, attribute_group
, case when lower(attribute_value) in ('min', 'max') then
        attribute_name || ': ' || attribute_value
    else attribute_name
    end as new_attribute_name
, case when lower(attribute_value) in ('min', 'max') then
        ie_value
    else attribute_value
    end as new_attribute_value
, ie_value
from _attr_value
join _crit_attribute_used_new cn using (attribute_id, attribute_group, attribute_name, attribute_value)
order by new_attribute_id;

create view v_crit_attribute_used_new as
select new_attribute_id, old_attribute_id
, attribute_group
, new_attribute_name as attribute_name
, new_attribute_value as attribute_value
, mandatory_default
, logic_l1_id
from crit_attribute_used_new
order by new_attribute_id
;
/*
select_from_db_schema_table.py rimsdw -q 'select * from ct_mm.crit_attribute_used_new order by new_attribute_id, ie_value'  \
    > crit_attribute_used_new_20200325.csv

select_from_db_schema_table.py rimsdw ct_mm.v_crit_attribute_used_new \
    > v_crit_attribute_used_new_20200325.csv
*/


-- 5) v_master_sheet_new: implement the logic and mandatory
drop table _master_sheet_new;
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
    when 'yes if exc' then exclusion is null
    end mandatory
, logic_l1_id
from _ms
join crit_attribute_used_new cn using (old_attribute_id, ie_value)
;

drop view if exists v_master_sheet_new;
create view v_master_sheet_new as
select new_attribute_id, old_attribute_id
, trial_id, person_id
, attribute_group, attribute_name, attribute_value
, attribute_match::int
, inclusion::int, exclusion::int
, mandatory::int
, logic_l1_id
from _master_sheet_new
order by person_id, trial_id, new_attribute_id
;
/*
select count(*) from v_master_sheet;
select count(*) from _master_sheet_new;
*/
