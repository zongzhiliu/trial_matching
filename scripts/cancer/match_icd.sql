/*** match attribute using ICD codes: icd_rex, icd_rex_other
Requires: crit_attribute_used, trial_attribute_used
    latest_icd
Results: _p_a_t_icd_rex
*/
drop table if exists _p_a_t_icd_rex cascade;
create table _p_a_t_icd_rex as
with cau as (
    select attribute_id, code_type, code, nvl(attribute_value_norm, '100.0')::float max_years
    from crit_attribute_used
    where code_type in ('icd_rex', 'icd_rex_other')
)
select person_id, trial_id, attribute_id
, case when code_type='icd_rex_other' then --Other primary malignancy
    bool_or(pca.py_re_search(icd_code, code, '') is not null
        and datediff(day, dx_date, current_date) <= 365.25 * max_years
        and icd_code !~ '${cancer_type_icd}')
    else bool_or(pca.py_re_search(icd_code, code, '') is not null
        and datediff(day, dx_date, current_date) <= 365.25 * max_years)
    end as match
from latest_icd
cross join cau
join trial_attribute_used using (attribute_id)
group by person_id, trial_id, attribute_id
, code_type, code, max_years
;
/*qc
select attribute_id, attribute_name, attribute_value, match, count(distinct person_id)
from _p_a_t_icd_rex join crit_attribute_used using (attribute_id)
where match
group by attribute_id, attribute_name, attribute_value, match
order by attribute_id, attribute_name, attribute_value, match
;
*/

