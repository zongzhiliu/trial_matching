drop table if exists _p_a_t_loinc cascade;
create table _p_a_t_loinc as
with cau as (
    select attribute_id, code_type, code
    , attribute_value
    , nvl(attribute_value_norm, '1')::float loinc_2_ie_factor
    from crit_attribute_used
    where code_type = 'loinc'
), tau as (
    select attribute_id, trial_id
    , nvl(inclusion, exclusion)::float ie_value
    from trial_attribute_used
    where inclusion != 'yes' --quickfix, waiting for KY's update
)
select attribute_id, code, listagg(distinct ie_value, ', ')
, loinc_code
from tau join cau using (attribute_id)
left join latest_lab on code=loinc_code
group by attribute_id, code, loinc_code
order by loinc_code
;
/*
select person_id, trial_id, attribute_id
, case lower(attribute_value)
    when 'min' then value_float * loinc_2_ie_factor >= ie_value
    when 'max' then value_float * loinc_2_ie_factor <= ie_value
    end as match
from latest_lab
join cau on code=loinc_code
join tau using (attribute_id)
;
--group by person_id, trial_id, attribute_id
--, code_type, code, max_years
select attribute_name, attribute_value, match, count(distinct person_id)
from _p_a_t_loinc
join crit_attribute_used using (attribute_id)
group by attribute_name, attribute_value, match
order by attribute_name, attribute_value, match
;
*/
