/***
Result: _p_a_t_mm_cancer_dx
Input: cplus_from_aplus.cancer_diagnosis_mm.m_protein_type
*/
drop table if exists _p_a_t_mm_cancer_dx cascade;
create table _p_a_t_mm_cancer_dx as
with tau as (
    select attribute_id, trial_id
    from trial_attribute_used
    join crit_attribute_used using (attribute_id)
    where code_type = 'mm_cancer_dx' and code='m_protein_type'
), act_stat as (
    select person_id, m_protein_type
    from cplus_from_aplus.cancer_diagnoses_mm
    join cplus_from_aplus.cancer_diagnoses using (cancer_diagnosis_id)
    join cohort using(person_id)
)
select person_id, trial_id, attribute_id
, m_protein_type=code_ext as match
from tau
cross join act_stat
;

create view qc_mm_cancer_dx as
select attribute_id, attribute_name, attribute_value
, count(distinct person_id)
from _p_a_t_mm_cancer_dx
where match
group by attribute_id, attribute_name, attribute_value
;
select * from qc_mm_cancer_dx;
