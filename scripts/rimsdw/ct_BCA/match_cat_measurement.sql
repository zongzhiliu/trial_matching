/*** match attribute using cat_measurement code
Requires: cohort, crit_attribute_used, trial_attribute_used
    cat_measurement
Results: _p_a_t_cat_measurement
*/
drop table if exists _p_a_t_cat_measurement cascade;
create table _p_a_t_cat_measurement as
with cau as (
    select attribute_id, code, attribute_value, attribute_value_norm
    from crit_attribute_used
    where code_type = 'cat_measurement'
), tau as (
    select attribute_id, trial_id
    , nvl(inclusion, exclusion) ie_value
    from trial_attribute_used
)
select person_id, trial_id, attribute_id, ie_value
, bool_or(case when code in ('menopausal_status', 'gender') then
        value = attribute_value
    else lower(value)=lower(ie_value) --er, pr, her2, tri_neg
    end) as match
from cat_measurement
join cau using (code)
join tau using (attribute_id)
group by person_id, trial_id, attribute_id, ie_value
;
/*
select attribute_id, attribute_name, attribute_value, ie_value, match
, count(distinct person_id) patients
from _p_a_t_cat_measurement
join crit_attribute_used using (attribute_id)
where match
group by attribute_id, attribute_name, attribute_value, ie_value, match
order by attribute_id, ie_value, match
;
*/
