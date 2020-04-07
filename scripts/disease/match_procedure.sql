/*** match attribute using ICD codes: icd_rex, icd_rex_other
Requires: crit_attribute_used, trial_attribute_used
    latest_proc, ref_proc_mapping
Results: _p_a_t_icd_rex
*/
drop table if exists _p_a_proc_icd_rex cascade;
create table _p_a_proc_icd_rex as
with cau as (
    select attribute_id, code
    from crit_attribute_used
    where code_type = 'proc_icd_rex'
)
select person_id, attribute_id
, True as match
from latest_proc join cau on context_name like 'ICD-%'
    and ct.py_contains(context_procedure_code, code)
group by person_id, attribute_id
;
/*
select count(*) from _p_a_proc_icd_rex;
*/
drop table if exists _p_a_cpt_mapping cascade;
create table _p_a_cpt_mapping as
with cau as (
    select attribute_id, code
    from crit_attribute_used
    where code_type = 'cpt_mapping'
), pm as (
    select proc_name, context_name, context_procedure_code::varchar
    from ref_proc_mapping
)
select person_id, attribute_id
, True as match
from cau
join pm on proc_name=code
join latest_proc using (context_name, context_procedure_code)
group by person_id, attribute_id
;
/*
select count(*) from _p_a_cpt_mapping;
*/

drop view if exists _p_a_t_procedure;
create view _p_a_t_procedure as
with cau as (
    select attribute_id
    from crit_attribute_used
    where code_type in ('proc_icd_rex', 'cpt_mapping')
), pa as (
    select person_id, attribute_id, match from _p_a_proc_icd_rex
    union all
    select person_id, attribute_id, match from _p_a_cpt_mapping
)
select person_id, trial_id, attribute_id
, nvl(match, False) as match
from (cohort cross join cau)
left join pa using (person_id, attribute_id)
join trial_attribute_used using (attribute_id)
;

/*
with tmp as (
    select attribute_id, attribute_name, attribute_value, code_type
    , match, count(distinct person_id) patients
    from _p_a_t_procedure join crit_attribute_used using (attribute_id)
    group by attribute_id, attribute_name, attribute_value, match, code_type
)
select attribute_id, attribute_name, attribute_value, code_type
, sum(case when match is True then patients end) as True_patients
, sum(case when match is False then patients end) as false_patients
from tmp
group by attribute_id, attribute_name, attribute_value, code_type
order by attribute_id, attribute_name, attribute_value
;

select * from _kinds_of_proc
where context_name like 'ICD%'
    and context_procedure_code ~ 'Z98.0' --'^0?49[.](0[1-4]|22)'
limit 99;
select * from _dx_icd
where context_name like 'ICD%'
    and context_diagnosis_code ~ 'V44' --'Z98.0'
limit 99;
*/

