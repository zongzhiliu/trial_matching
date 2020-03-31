/*
Result: v_master_sheet_new
*/
drop table if exists _crit_attribute_logic;
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
create table _crit_attribute_used_new as
select attribute_id, attribute_group, attribute_name
, attribute_value
, (mandatory_default ilike 'y%')::int as mandatory_default
, logic_l1, logic_l2
from crit_attribute_used cau
join _crit_attribute_logic cal using (attribute_id)
;
/*
select count(*), count(distinct attribute_id) from v_crit_attribute_used;
select count(*), count(distinct attribute_id) from _crit_attribute_used_new;
select * from _crit_attribute_used_new where logic_l1='moa.or';
select * from crit_attribute_used where logic='moa.or';
*/
-- logic
-- 3) _attr_value
drop table if exists _attr_value;
create table _attr_value as
select distinct attribute_id, attribute_group, attribute_name
, value as attribute_value, nvl(inclusion, exclusion) ie_value
from v_master_sheet
;
/*
select_from_db_schema_table.py rdmsdw -q 'select * from ${working_schema}._attr_value order by attribute_id, ie_value'  > _attr_value.csv
-- min/max only, the LOT min 1/2 are identical(defined as any sys therapy)
*/
-- 4) crit_attribute_used_new, v_crit_attribute_used_new
drop table if exists crit_attribute_used_new cascade;
create table crit_attribute_used_new as
select row_number() over (order by attribute_id, attribute_value, ie_value) as new_attribute_id
, attribute_id as old_attribute_id
, attribute_group
, case when lower(attribute_value) ~ '^(min|max|positive)'
    then attribute_name || ': ' || attribute_value
    else attribute_name
    end as new_attribute_name
, case when lower(attribute_value) ~ '^(min|max|positive)'
    then ie_value
    else attribute_value
    end as new_attribute_value
, ie_value
, mandatory_default, logic_l1, logic_l2
from _attr_value
join _crit_attribute_used_new cn using (attribute_id, attribute_group, attribute_name, attribute_value) -- tobe fixed
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
select_from_db_schema_table.py rdmsdw ct_cd.v_crit_attribute_used_new \
    > v_crit_attribute_used_new_$(today_stamp).csv

select count(distinct attribute_id) from crit_attribute_used;
select count(*), count(distinct old_attribute_id) from crit_attribute_used_new;
select * from v_crit_attribute_used_new where logic_l1='moa.or';
*/


-- 5) v_master_sheet_new: implement the logic and mandatory
drop table if exists _master_sheet_new;
create table _master_sheet_new as
with _ms as (
    select attribute_id as old_attribute_id
    , trial_id, person_id
    , inclusion, exclusion, attribute_match
    , nvl(inclusion, exclusion) ie_value
    , mandatory
    from v_master_sheet
)
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
