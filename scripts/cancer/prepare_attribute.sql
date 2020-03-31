
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
drop table if exists trial_attribute_used cascade;
create table trial_attribute_used as
select tar.*
from trial_attribute_raw tar
join crit_attribute_raw using (attribute_id)
where nvl(inclusion, exclusion) is not null
;
/*
select count(*) from trial_attribute_used;
*/
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
, logic
from crit_attribute_used
order by regexp_substr(attribute_id, '[0-9]+$')::int
;
/*qc
select count(*) from crit_attribute_used;
    --114
*/

create view trial_attribute_ie as
select trial_id, attribute_id
, (inclusion is not null)::int as ie
, nvl(inclusion, exclusion) as ie_value
from trial_attribute_used
;


