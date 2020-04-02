/*
Fix the issue of same trial have various number of attributes for different patients
On the data_bridge server

runned for PCA

alter table crit_attribute_used rename to crit_attribute_used_raw;
create table crit_attribute_used as
select attribute_id, attribute_group, attribute_name
, value attribute_value
, mandated as mandatory_default
, crit_id::varchar||'.or' as logic_l1
from crit_attribute_used_raw
;

alter table trial_attribute_used rename to trial_attribute_used_raw;
create table trial_attribute_used as
select r.*
, mandatory_default as mandatory
from trial_attribute_used_raw r
join crit_attribute_used using (attribute_id)
;
*/

/*
on redshift
Input: v_master_sheet_new, v_crit_attribute_new
output: v_master_sheet_n
Then: load and expand on data_bridge
*/
create view v_master_sheet_n as
with _m as (
    select new_attribute_id, trial_id, person_id
    , attribute_match
    from v_master_sheet_new
), _ta as (
    select distinct trial_id, new_attribute_id
    , inclusion, exclusion, mandatory
    from v_master_sheet_new
), _p as (
    select distinct person_id
    from v_master_sheet_new
)
select new_attribute_id, trial_id, person_id
, inclusion, exclusion, mandatory
, attribute_match
from (_p cross join _ta)
left join _m using (new_attribute_id, trial_id, person_id)
;
/*
select * from v_master_sheet_n
order by person_id, trial_id, new_attribute_id
limit 99;
select trial_id, person_id
, count(distinct new_attribute_id)
from v_master_sheet_n
group by trial_id, person_id
order by trial_id, person_id
limit 99 offset 20000;
*/
