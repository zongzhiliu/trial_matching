/*** match attribute using misc_measurement code
Requires: crit_attribute_used, trial_attribute_used
    demo, latest_eog, latest_karnofsky, lot
Results: _p_a_t_misc_measurement
*/
drop table if exists _p_a_t_misc_measurement cascade;
create table _p_a_t_misc_measurement as
with cau as (
    select attribute_id, code, attribute_value
    from crit_attribute_used
    where code_type = 'misc_measurement'
), tau as (
    select attribute_id, trial_id
    , nvl(inclusion, exclusion)::float ie_value
    from trial_attribute_used
    --where nvl(inclusion, exclusion) != 'yes' --quickfix: to remove later
)
select person_id, trial_id, attribute_id
, ie_value
, case lower(attribute_value)
    when 'min' then value_float >= ie_value
    when 'max' then value_float <= ie_value
    end as match
from misc_measurement
join cau using (code)
join tau using (attribute_id)
;
/*
with tmp as (
    select attribute_id, attribute_name, attribute_value, ie_value
    , match, count(distinct person_id) patients
    from _p_a_t_misc_measurement join crit_attribute_used using (attribute_id)
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

