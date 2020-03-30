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
create temporary table pa as
with a as (
    select attribute_id, code
    from crit_attribute_used
    where code_type = 'icd_earliest'
)
select person_id, attribute_id
, dx_date
from (select *, row_number() over (
        partition by person_id, attribute_id
        order by dx_date, icd_code)
    from a
    join earliest_icd on ct.py_contains(icd_code, code))
where row_number=1
;
/*
select count(*), count(distinct attribute_id||person_id) from pa;
error message min(dx_date)
--, min(dx_date) as dx_date
--group by (person_id, attribute_id)
could not identify an ordering operator for type record
HINT:  Use an explicit ordering operator or modify the query.
*/

drop table if exists _p_a_t_icd_earliest cascade;
create table _p_a_t_icd_earliest as
with pat as (
    select person_id, attribute_id, trial_id
    , ie_value
    , regexp_substr(ie_value, '^[0-9]+')::float * code_transform::float as v_years
    , attribute_value, dx_date
    from pa
    join crit_attribute_used using (attribute_id)
    join trial_attribute_ie using (attribute_id)
)
select person_id, attribute_id, trial_id
, ie_value
, case lower(attribute_value)
    when 'min' then datediff(day, dx_date, current_date)/365.25 >= v_years
    when 'max' then datediff(day, dx_date, current_date)/365.25 <= v_years
    end as match
from pat
;
/*
select count(*), count(distinct person_id||attribute_id||trial_id) from _p_a_t_icd_earliest;
with tmp as (
    select attribute_id, attribute_name, attribute_value, code_type, ie_value
    , match, count(distinct person_id) patients
    from _p_a_t_icd_earliest join crit_attribute_used using (attribute_id)
    group by attribute_id, attribute_name, attribute_value, match, code_type, ie_value
)
select attribute_id, attribute_name, attribute_value, code_type, ie_value
, sum(case when match is True then patients end) as True_patients
, sum(case when match is False then patients end) as false_patients
from tmp
group by attribute_id, attribute_name, attribute_value, code_type, ie_value
order by attribute_id, attribute_name, attribute_value
;
*/

drop view if exists _p_a_t_diagnosis;
create view _p_a_t_diagnosis as
with cau as (
    select attribute_id, attribute_value
    from crit_attribute_used
    where code_type in ('icd_rex', 'icd_le_tempo')
), pa as (
    select person_id, attribute_id, match from _p_a_icd_rex
    union all
    select person_id, attribute_id, match from _p_a_icd_le_tempo
)
select person_id, trial_id, attribute_id
, attribute_value , nvl(match, False) as match
from (cohort cross join cau)
left join pa using (person_id, attribute_id)
join trial_attribute_used using (attribute_id)
union all
select person_id, trial_id, attribute_id
, attribute_value||'='||ie_value, match
from _p_a_t_icd_earliest join crit_attribute_used using (attribute_id)
;
/*qc
with tmp as (
    select attribute_id, attribute_name, pat.attribute_value, code_type
    , match, count(distinct person_id) patients
    from _p_a_t_diagnosis pat join crit_attribute_used using (attribute_id)
    group by attribute_id, attribute_name, pat.attribute_value, match, code_type
)
select attribute_id, attribute_name, attribute_value, code_type
, sum(case when match is True then patients end) as True_patients
, sum(case when match is False then patients end) as false_patients
from tmp
group by attribute_id, attribute_name, attribute_value, code_type
order by attribute_id, attribute_name, attribute_value
;
*/

