/* match PSA at diagnosis from cancer_diagnoses_pca
Result: _p_a_t_psa_at_diagnosis
Require: cplus_from_aplus 
*/

drop table if exists _p_a_t_psa_at_diagnosis;
create table _p_a_t_psa_at_diagnosis as
select person_id, trial_id
, ie_value::float as value
, attribute_id
, bool_or (case attribute_id
    when 386 then psa>=value --min
    when 387 then psa<=value --max
    end) as match
, listagg(psa::varchar, '| ') as patient_value
from cohort
join trial_attribute_used on attribute_id in (386, 387)
join cplus_from_aplus.cancer_diagnoses using (person_id)
join cplus_from_aplus.cancer_diagnoses_pca using (cancer_diagnosis_id)
where psa is not null
group by person_id, attribute_id, trial_id, ie_value
;
/*
select attribute_id, attribute_value, value, match
, count(distinct person_id)
from _p_a_t_psa_at_diagnosis
join crit_attribute_used using (attribute_id)
where match
group by attribute_id, attribute_value, value, match
order by attribute_id, attribute_value, value, match
;
select count(distinct person_id)
from cohort
join cplus_from_aplus.cancer_diagnoses using (person_id)
join cplus_from_aplus.cancer_diagnoses_pca using (cancer_diagnosis_id)
where psa is not null
;
--1643
*/
