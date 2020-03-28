/*** match attribute using ICD codes: icd_rex, icd_rex_other
Requires: crit_attribute_used, trial_attribute_used
    latest_icd
Results: _p_a_t_icd_rex
*/
drop table if exists _p_a_icd_rex cascade;
create table _p_a_icd_rex as
with cau as (
    select attribute_id, code
    from crit_attribute_used
    where code_type = 'icd_rex'
), pd as (
    select mrn person_id, icd_code
    from latest_icd
)
select person_id, attribute_id
, True as match
from pd join cau on ct.py_contains(icd_code, code)
group by person_id, attribute_id
;

drop table if exists _p_a_icd_le_tempo cascade;
create table _p_a_icd_le_tempo as
with cau as (
    select attribute_id, code, code_transform::float max_years
    from crit_attribute_used
    where code_type = 'icd_le_tempo'
)
select person_id, attribute_id
, True as match
from latest_icd join cau on ct.py_contains(icd_code, code)
    and datediff(day, dx_date, current_date)/365.25 <= max_years
group by person_id, attribute_id
;
/*
select count(*) from _p_a_icd_le_tempo;
*/
------------------------------------------------------------ 
-- next icd_earliest
drop view if exists _p_a_t_diagnosis;
create view _p_a_t_diagnosis as
with cau as (
    select attribute_id
    from crit_attribute_used
    where code_type in ('icd_rex', 'icd_le_tempo')
), pa as (
    select person_id, attribute_id, match from _p_a_icd_rex
    union all
    select person_id, attribute_id, match from _p_a_icd_le_tempo
)
select person_id, trial_id, attribute_id
, nvl(match, False) as match
from (cohort cross join cau)
left join pa using (person_id, attribute_id)
join trial_attribute_used using (attribute_id)
;
/*qc
with tmp as (
    select attribute_id, attribute_name, attribute_value, code_type
    , match, count(distinct person_id) patients
    from _p_a_t_diagnosis join crit_attribute_used using (attribute_id)
    group by attribute_id, attribute_name, attribute_value, match, code_type
)
select attribute_id, attribute_name, attribute_value, code_type
, sum(case when match is True then patients end) as True_patients
, sum(case when match is False then patients end) as false_patients
from tmp
group by attribute_id, attribute_name, attribute_value, code_type
order by attribute_id, attribute_name, attribute_value
;
*/

