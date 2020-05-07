/*
replace ct_${concer_type}
*/
-- 1). modify the mandited column
/*
crit_attribute_mapping_raw
load_into_db_schema_some_csvs.py rimsdw ct_bca crit_attribute_mapping_raw.csv -d
*/

set search_path=ct_bca;
-- 2). _crit_attriburte_used_new: PCA specific

create table _crit_attribute_logic as
with tmp as (
    select attribute_id, logic
    , split_part(logic, '/', 1) p1
    , split_part(logic, '/', 2) p2
    from crit_attribute_used
)
select attribute_id, logic
, case when p1 is null or p1=''
    then attribute_id
    else p1
    end logic_l1
, case when p2 is null or p2=''
    then attribute_id
    else p2
    end logic_l2
from tmp
order by logic
;

drop table if exists _crit_attribute_used_new;
create table _crit_attribute_used_new as (
select attribute_id
, new_attribute_group as attribute_group
, nvl(new_attribute_name, '_') as attribute_name
, new_value as attribute_value
, cau.attribute_mandated as mandatory_default
-- , nvl(cau.logic, attribute_id||'.or') as logic_l1_id
, logic_l1, logic_l2
from crit_attribute_used cau
join _crit_attribute_logic cal using (attribute_id)
join crit_attribute_mapping_raw cam using (attribute_id)
);
/*
select count(*), count(distinct attribute_id) from v_crit_attribute_used;
select count(*), count(distinct attribute_id) from _crit_attribute_used_new;
select * from _crit_attribute_used_new;
*/
-- logic
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
    , mandatory
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
select_from_db_schema_table.py rimsdw -q 'select * from ct_bca._attr_value order by attribute_id, ie_value'  > _attr_value.csv
-- min/max/positive need to be dealed
*/
-- 4) crit_attribute_used_new, v_crit_attribute_used_new
drop table crit_attribute_used_new cascade;
create table crit_attribute_used_new as
select row_number() over (order by attribute_id, attribute_value, ie_value) as new_attribute_id
, attribute_id as old_attribute_id
, attribute_group
, case when lower(attribute_value) ~ '^(min|max|positive)' --BCA customized
    then attribute_name || ': ' || attribute_value
    else attribute_name
    end as new_attribute_name
, case when lower(attribute_value) ~ '^(min|max|positive)' --BCA customized
    then ie_value
    else attribute_value
    end as new_attribute_value
, ie_value
, mandatory_default, logic_l1, logic_l2
from _attr_value
join _crit_attribute_used_new cn using (attribute_id, attribute_group, attribute_name, attribute_value)
order by new_attribute_id;

create view v_crit_attribute_used_new as
select new_attribute_id, old_attribute_id
, attribute_group
, new_attribute_name as attribute_name
, new_attribute_value as attribute_value
, mandatory_default
, logic_l1, logic_l2
from crit_attribute_used_new
order by new_attribute_id
;
/*
select_from_db_schema_table.py rimsdw ct_bca.v_crit_attribute_used_new \
    > v_crit_attribute_used_new_$(today_stamp).csv

select count(distinct attribute_id) from crit_attribute_used;
select count(*), count(distinct old_attribute_id) from crit_attribute_used_new;
    -- 152, 126
*/


-- 5) v_master_sheet_new: implement the logic and mandatory
drop table _master_sheet_new;
create table _master_sheet_new as
select new_attribute_id, old_attribute_id
, trial_id, person_id
, attribute_match
, inclusion is not null as inclusion
, exclusion is not null as exclusion
, mandatory
from _ms
join crit_attribute_used_new cn using (old_attribute_id, ie_value)
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
, mandatory::int
, logic_l1, logic_l2 -- from cn
from _master_sheet_new
join v_crit_attribute_used_new cn using (new_attribute_id, old_attribute_id)
order by person_id, trial_id, new_attribute_id
;

/*
select count(*) from v_master_sheet;
select count(*) from _master_sheet_new;

select * from v_master_sheet_new
join (select distinct trial_id from v_master_sheet_new 
	where attribute_name ilike 'triple%' limit 3
	) using (trial_id)
order by person_id, trial_id, new_attribute_id
limit 99;
*/
