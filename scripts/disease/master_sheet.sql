/***
Requires:
    _master_match
    , trial_attribute_used, crit_attribute_used
Results:
    master_match, _master_sheet
Settings:
*/

-- set match as null by default for each patient
drop view if exists master_match;
create view master_match as
select attribute_id, trial_id, person_id
, bool_or(match) as attribute_match --quick fix: multiple matches
from (trial_attribute_used
    cross join cohort)
left join _master_match using (attribute_id, trial_id, person_id)
group by attribute_id, trial_id, person_id
;

drop table if exists _master_sheet cascade;
create table _master_sheet as
select trial_id, person_id, attribute_id
, attribute_group, attribute_name, attribute_value
, inclusion, exclusion
, attribute_match
--, nvl(ie_mandatory, mandatory_default) ilike 'y%' as mandatory
, nvl(mandatory, mandatory_default) ilike 'y%' as mandatory
from master_match
join (select *, ie_mandatory mandatory from trial_attribute_used)
    using (attribute_id, trial_id) --unnecessary for the new master_match
join crit_attribute_used using (attribute_id)
;
/*
select trial_id, person_id, count(*)
from v_master_sheet
where person_id::varchar like '%000'
group by trial_id, person_id
order by trial_id, person_id
limit 99
;
*/
-- to be deprecated: mv into deliver
create or replace view v_master_sheet as
select trial_id, person_id
, attribute_id, attribute_group, attribute_name, attribute_value
, inclusion, exclusion
, attribute_match
, mandatory
from _master_sheet
order by trial_id, person_id, regexp_substr(attribute_id, '[0-9]+$')::int
;
/* qc
select * from v_master_sheet
order by person_id, trial_id, attribute_id
limit 100;
select count(distinct person_id), count(distinct trial_id), count(distinct attribute_id) from v_master_sheet;

select count(*) from v_master_sheet; --20,172,318
select count(*) from (select distinct trial_id, person_id, attribute_id from v_master_sheet); --20, 119,807
*/

