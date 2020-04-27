/*** match attribute using ICD codes: icd_rex, icd_rex_other
Requires: crit_attribute_used
, latest_icd
Results: _p_a_icd_rex
*/
drop table if exists _p_a_icd_rex cascade;
create table _p_a_icd_rex as
with cau as (
    select attribute_id, code_type, code
    , case when code_transform is null then 100
        else regexp_substr(attribute_value, '[0-9]+')::int * code_transform::float
        end max_years
    from crit_attribute_used
    where code_type in ('icd_rex', 'icd_rex_other', 'icd_le_tempo')
)
select person_id, attribute_id
, case when code_type='icd_rex_other' then --Other primary malignancy
        bool_or(icd_code !~ '${cancer_type_icd}') --bool_or or and??
    else True
    end as match
from latest_icd li
join cau on ct.py_contains(icd_code::varchar, code)
    and datediff(day, dx_date, '${protocal_date}')/365.25 <= max_years
group by person_id, attribute_id
, code_type, code, max_years
;

create view qc_match_icd as
select attribute_id, attribute_name, attribute_value
, count(distinct person_id)
from _p_a_icd_rex join crit_attribute_used using (attribute_id)
where match
group by attribute_id, attribute_name, attribute_value
order by attribute_id, attribute_name, attribute_value
;
