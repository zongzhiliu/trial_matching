/***
 * master match: need modifying for each cancer type!!
Requires: trial_attribute_used
    _p_a_t_...
Results:
    master_match
*/
--SET search_path=ct_${cancer_type};

drop table if exists _master_match cascade;
create table _master_match as (
    select attribute_id, trial_id, person_id, match from _p_a_t_icd_rex
    union select attribute_id, trial_id, person_id, match from _p_a_t_loinc
    union select attribute_id, trial_id, person_id, match from _p_a_t_rxnorm
    union select attribute_id, trial_id, person_id, match from _p_a_t_misc_measurement
    union select attribute_id, trial_id, person_id, match from _p_a_t_aof
    union select attribute_id, trial_id, person_id, match from _p_a_t_mm_active_status
)
;
/*
select attribute_id, attribute_name, code_type, count(distinct person_id)
from _master_match
join crit_attribute_used using (attribute_id)
group by attribute_id, attribute_name, code_type
order by attribute_id limit 99;
-- loinc, misc_meas, aof have less patients
*/

-- set match as null by default for each patient
create view master_match as
select attribute_id, trial_id, person_id, match
from (trial_attribute_used
    cross join cohort)
left join _master_match using (attribute_id, trial_id, person_id)
;


