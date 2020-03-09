
/***
* trial, crit, attributes
Require:
    trial_attribute_raw
    crit_attribute_raw
Result:
    trial_attribute_used
    crit_attribute_used
    v_crit_attribute_used
*/
-- set search_path=ct_${cancer_type};
-- trial_attribute_used
drop table if exists trial_attribute_used;
create table trial_attribute_used as
select * from trial_attribute_raw
where nvl(inclusion, exclusion) is not null
;
-- crit_attribute_used
drop table if exists crit_attribute_used cascade;
create table crit_attribute_used as
select *
from crit_attribute_raw c
where attribute_id in (select distinct attribute_id
    from trial_attribute_used)
;

drop view if exists v_crit_attribute_used;
create view v_crit_attribute_used as
select attribute_id, attribute_group, attribute_name, attribute_value value
, mandated, logic
from crit_attribute_used
order by attribute_id
;
/*qc
select count(*) from crit_attribute_used;
    --170
*/
