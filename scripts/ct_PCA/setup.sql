/***
Dependencies
Results:
    trial_attribute_used
    crit_attribute_used
*/

-- trial_attribute_used
drop table if exists trial_attribute_used cascade;
create table trial_attribute_used as
select *
, inclusion is not null as ie_flag
, btrim(nvl(inclusion, exclusion)) ie_value
from (select distinct * from _trial_attribute_raw) --quickfix
where ie_value is not null
    and ie_value !~ 'yes <[24]W' --quickfix
;

with obs as(
    select count(*) from trial_attribute_used
), exp as (
    select count(*) from (select distinct trial_id, attribute_id
        from trial_attribute_used)
)
select ct.assert(
    (select count from obs) = (select count from exp)
    , 'records should be have distinct keys')
;
/* summary
with tmp as (
    select attribute_id, ie_value
    , count(trial_id) trials
    from trial_attribute_used
    group by attribute_id, ie_value
)
select attribute_id, ie_value, trials
, attribute_group || '| ' || attribute_name || '| ' || attribute_value
from tmp join _crit_attribute_raw a using (attribute_id)
order by attribute_id
;
*/
-- crit_attribute_used
--alter table crit_attribute_used rename to crit_attribute_used_old_20200408;
drop table if exists crit_attribute_used cascade;
create table crit_attribute_used as
select attribute_id, attribute_group, attribute_name, attribute_value
--, mandatory_default, logic_default
from _crit_attribute_raw c
join (select distinct attribute_id
    from trial_attribute_used) using (attribute_id)
;
-- assert
select ct.assert(count(*)=count(distinct attribute_id),
    'No redundant attribute_ids')
from crit_attribute_used;
/*qc
select count(*) from crit_attribute_used;
    --170
    --183
-- to be updated later using all-null matches
drop view v_crit_attribute_used;
create or replace view v_crit_attribute_used as
select attribute_id, attribute_group, attribute_name, attribute_value
, mandatory_default, logic_default
from crit_attribute_used
order by attribute_id
;
*/
