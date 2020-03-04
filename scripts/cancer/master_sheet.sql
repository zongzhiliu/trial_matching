/***
Requires:
    master_match, trial_attribute_used, crit_attribute_used
Results:
    v_master_sheet
Settings:
*/
SET search_path=ct_${cancer_type};

/***
 * master_sheet
 */
drop table if exists _master_sheet cascade;
create table _master_sheet as
select trial_id, person_id
, attribute_id, attribute_group, attribute_name, value
, inclusion, exclusion
, patient_value, match as attribute_match
from master_match
join trial_attribute_used using (attribute_id, trial_id)
join crit_attribute_used using (attribute_id)
;

create or replace view v_master_sheet as
select trial_id, person_id+3040 as person_id
, attribute_id, attribute_group, attribute_name, value
, inclusion, exclusion
, attribute_match
, patient_value as patient_value_incomplete
from _master_sheet
join demo using (person_id) --necessary?
order by trial_id, person_id, attribute_id
;
/* qc
select * from v_master_sheet
order by person_id, trial_id, attribute_id
limit 100;
select count(distinct person_id), count(distinct attribute_id) from v_master_sheet;
select count(distinct trial_id), count(distinct attribute_id) from trial_attribute_used;
*/

