/***
Dependencies
Results:
    trial_attribute_used
    crit_attribute_used
*/


/***
* trial, crit, attributes
*/
-- trial_attribute_used
drop table if exists trial_attribute_used cascade;
create table trial_attribute_used as
select *
, inclusion is not null as ie_flag
, nvl(inclusion, exclusion) ie_value
from _trial_attribute_raw
where ie_value is not null
    and ie_value !~ 'yes <[24]W' --quickfix
;
/*
with tmp as (
    select attribute_id
    , listagg(distinct nvl(inclusion, exclusion), '| ') ie_values
    from trial_attribute_used
    group by attribute_id
)
select attribute_id, ie_values, a.*
from tmp join crit_attribute_raw a using (attribute_id)
order by attribute_id
;
*/
-- crit_attribute_used
--alter table crit_attribute_used rename to crit_attribute_used_old_20200408;
drop table if exists crit_attribute_used cascade;
create table crit_attribute_used as
select attribute_id, attribute_group, attribute_name, attribute_value
, mandatory_default, logic_default
from _crit_attribute_raw c
join (select distinct attribute_id
    from trial_attribute_used) using (attribute_id)
;
-- assert
select count(*), count(distinct attribute_id) from crit_attribute_used;
--drop view v_crit_attribute_used;
--create or replace view v_crit_attribute_used as
--select attribute_id, attribute_group, attribute_name, attribute_value
--, mandatory_default, logic_default
--from crit_attribute_used
--order by attribute_id
--;
/*qc
select count(*) from crit_attribute_used;
    --170
    --183
*/
