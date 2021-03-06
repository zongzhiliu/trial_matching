/*** match attribute for cancer stage
Requires: cohort, crit_attribute_used, trial_attribute_used
    stage
Results: _p_a_t_stage
*/
drop table if exists _p_a_t_stage cascade;
create table _p_a_t_stage as
with cau as (
    select attribute_id, code_type, code
    , attribute_value, attribute_value_norm
    from crit_attribute_used
    where code_type in ('stage_base', 'stage_like')
), tau as (
    select attribute_id, trial_id
    , nvl(inclusion, exclusion) ie_value
    from trial_attribute_used
    --where ie_value = 'yes'
)
select person_id, trial_id, attribute_id
, bool_or(case code_type
    when 'stage_base' then stage_base = code
    when 'stage_like' then stage like code
    end) as match
from (stage cross join cau)
join tau using (attribute_id)
group by person_id, trial_id, attribute_id
;
/*
select attribute_id, attribute_name, code, attribute_value, ie_value, match
, count(distinct person_id) patients
from _p_a_t_stage
join crit_attribute_used using (attribute_id)
where match
group by attribute_id, attribute_name, code, attribute_value, ie_value, match
order by attribute_id, ie_value, match
;
*/
