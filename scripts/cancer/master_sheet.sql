/***
Requires:
    master_match, trial_attribute_used, crit_attribute_used
Results:
    v_master_sheet
Settings:
*/
-- set match as null by default for each patient
drop view if exists master_match;
create view master_match as
select attribute_id, trial_id, person_id, match
from (trial_attribute_used
    cross join cohort)
left join _master_match using (attribute_id, trial_id, person_id)
;

/***
 * master_sheet
 */
drop table if exists _master_sheet cascade;
create table _master_sheet as
select trial_id, person_id, attribute_id
, attribute_group, attribute_name, attribute_value
, inclusion, exclusion
, match as attribute_match
, nvl(ie_mandatory, attribute_mandated='yes') as mandatory
from master_match
join trial_attribute_used using (attribute_id, trial_id) --unnecessary for the new master_match
join crit_attribute_used using (attribute_id)
;

create or replace view v_master_sheet as
select trial_id, person_id+3040 as person_id
, attribute_id, attribute_group, attribute_name, attribute_value
, inclusion, exclusion
, attribute_match
, mandatory
--, patient_value as patient_value_incomplete
from _master_sheet
join cohort using (person_id) --unnecessary for the new master_match
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

