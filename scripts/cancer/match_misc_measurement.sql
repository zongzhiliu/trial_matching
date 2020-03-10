create temporary table misc_meas as (
    select person_id, 'age' as code
    , datediff(day, date_of_birth, current_date) / 365.25 as value_float
    from demo
    union select person_id, 'ecog', ecog_ps
    from latest_ecog
    union select person_id, 'karnosky', karnofsky_pct
    from latest_karnofsky
    union select person_id, 'lot', n_lot
    from lot
);
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
)
select person_id, trial_id, attribute_id
, ie_value
, case lower(attribute_value)
    when 'min' then value_float >= ie_value
    when 'max' then value_float <= ie_value
    end as match
from misc_meas
join cau using (code)
join tau using (attribute_id)
;
/*
select attribute_id, attribute_name, attribute_value, ie_value, match
, count(distinct person_id) patients
from _p_a_t_misc_measurement
join crit_attribute_used using (attribute_id)
where match
group by attribute_id, attribute_name, attribute_value, ie_value, match
order by attribute_id, ie_value, match
;
*/

