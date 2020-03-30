/*** match attribute using loinc codes
Requires: crit_attribute_used, trial_attribute_used
    latest_lab
Results: _p_a_t_loinc
*/
drop table if exists _p_a_t_loinc cascade;
create table _p_a_t_loinc as
with cau as (
    select attribute_id, code_type, code
    , attribute_value
    , nvl(code_transform, '1')::float loinc_2_ie_factor
    from crit_attribute_used
    where code_type = 'loinc'
), tau as (
    select attribute_id, trial_id
    , nvl(inclusion, exclusion)::float ie_value
    from trial_attribute_used
    --where inclusion != 'yes' --quickfix, waiting for KY's update
)
select person_id, trial_id, attribute_id
, ie_value
, case lower(attribute_value)
    when 'min' then value_float * loinc_2_ie_factor >= ie_value
    when 'max' then value_float * loinc_2_ie_factor <= ie_value
    end as match
from latest_lab
join cau on code=loinc_code
join tau using (attribute_id)
;

/*
select count(*), count(distinct person_id) from _p_a_t_loinc;
with tmp as (
    select attribute_id, attribute_name, attribute_value, ie_value
    , match, count(distinct person_id) patients
    from _p_a_t_loinc join crit_attribute_used using (attribute_id)
    group by attribute_id, attribute_name, attribute_value, ie_value, match
)
select attribute_id, attribute_name, attribute_value, ie_value
, sum(case when match is True then patients end) as True_patients
, sum(case when match is False then patients end) as false_patients
from tmp
group by attribute_id, attribute_name, attribute_value, ie_value
order by attribute_id, attribute_name, attribute_value
;
*/
