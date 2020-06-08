/***
Result: _p_a_t_mm_active_status
Input: cplus_from_aplus.cancer_diagnosis_mm.mm_active_status
*/
drop table if exists _p_a_t_mm_active_status cascade;
create table _p_a_t_mm_active_status as
with tau as (
    select attribute_id, trial_id
    from trial_attribute_used
    join crit_attribute_used using (attribute_id)
    where code = 'mm_active_status'
), act_stat as (
    select person_id, mm_active_status
    from cplus_from_aplus.cancer_diagnoses_mm
    join cplus_from_aplus.cancer_diagnoses using (cancer_diagnosis_id)
    join cohort using(person_id)
)
select person_id, trial_id, attribute_id
, case mm_active_status
    when 'Active'
        then False
    when 'Smoldering'
        then True
    end as match
from tau
cross join act_stat
;

create view qc_mm_smoldering as
select match, count(distinct person_id)
from _p_a_t_mm_active_status
group by match
;
select * from qc_mm_smoldering;
