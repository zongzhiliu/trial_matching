/***
Requires:
    _p_a_...
    _p_a_t_...
    trial_attribute_used
Results:
    master_match
Settings:
*/
SET search_path=ct_${cancer_type};

/***
 * master match: need modifying for each cancer type!!
 */
drop table _p_a_t_match;
create table _p_a_t_match as
select attribute_id, trial_id, person_id, patient_value::varchar, match from _p_a_t_age
union select attribute_id, trial_id, person_id, patient_value::varchar, match from _p_a_t_weight
union select attribute_id, trial_id, person_id, patient_value::varchar, match from _p_a_t_lab
union select attribute_id, trial_id, person_id, patient_value::varchar, match from _p_a_t_blood_pressure
;
/*
select * from _p_a_t_lab join crit_attribute_used using (attribute_id)
order by person_id, trial_id, attribute_id limit 99;
*/
drop table _p_a_match cascade;
create table _p_a_match as
--select attribute_id, person_id, patient_value::varchar, match from _p_a_age
--select attribute_id, person_id, patient_value::varchar, match from _p_a_histology
select attribute_id, person_id, patient_value::varchar, match from _p_a_stage
union select attribute_id, person_id, patient_value::varchar, match from _p_a_lab
union select attribute_id, person_id, patient_value::varchar, match from _p_a_lot
union select attribute_id, person_id, patient_value::varchar, match from _p_a_chemotherapy
union select attribute_id, person_id, patient_value::varchar, match from _p_a_hormone_therapy
union select attribute_id, person_id, patient_value::varchar, match from _p_a_immunotherapy
union select attribute_id, person_id, patient_value::varchar, match from _p_a_targetedtherapy
union select attribute_id, person_id, patient_value::varchar, match from _p_a_disease
union select attribute_id, person_id, patient_value::varchar, match from _p_a_ecog
union select attribute_id, person_id, patient_value::varchar, match from _p_a_karnofsky
union select attribute_id, person_id, patient_value::varchar, match from _p_a_mutation
;
/*
select * from _p_a_match --limit 90;
join crit_attribute_used using (attribute_id)
order by person_id, attribute_id limit 99;
*/

drop view if exists _master_match;
create view _master_match as
select attribute_id, trial_id, person_id, patient_value::varchar, match
from _p_a_t_match
union
select attribute_id, trial_id, person_id, patient_value::varchar, match
from _p_a_match join trial_attribute_used using (attribute_id)
;

/***
* finish the master_match
*/
drop table if exists master_match;
create table master_match as
select attribute_id, trial_id, person_id, patient_value::varchar, match
from _p_a_t_gleason
union
select attribute_id, trial_id, person_id, patient_value::varchar, match
from _p_a_histology join trial_attribute_used using (attribute_id)
union
select attribute_id, trial_id, person_id, patient_value::varchar, match
from _master_match
;
