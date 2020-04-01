/*** match attribute using ICD codes: icd_rex, icd_rex_other
Requires: crit_attribute_used, trial_attribute_used
    latest_icd
Results: _p_a_t_icd_rex
*/
--drop view if exists _p_a_t_icd_rex cascade;
drop table if exists _p_a_icd_rex cascade;
create table _p_a_icd_rex as
with cau as (
    select attribute_id, code_type, code, nvl(attribute_value_norm, '100.0')::float max_years
    from crit_attribute_used
    where code_type in ('icd_rex', 'icd_rex_other')
)
select person_id, attribute_id
, case when code_type='icd_rex_other' then --Other primary malignancy
        bool_or(icd_code !~ '${cancer_type_icd}')
    else True
    end as match
from latest_icd li
join cau on ct.py_contains(icd_code, code)
    and datediff(day, dx_date, '${protocal_date}')/365.25 <= max_years
group by person_id, attribute_id
, code_type, code, max_years
;

drop view if exists _p_a_t_icd_rex;
create view _p_a_t_icd_rex as
select person_id, trial_id, attribute_id
, nvl(match, False) as match
from cohort
left join _p_a_icd_rex using (person_id)
left join trial_attribute_used using (attribute_id)
;
/*qc
select attribute_id, attribute_name, attribute_value, match, count(distinct person_id)
from _p_a_t_icd_rex join crit_attribute_used using (attribute_id)
where match
group by attribute_id, attribute_name, attribute_value, match
order by attribute_id, attribute_name, attribute_value, match
;
*/

