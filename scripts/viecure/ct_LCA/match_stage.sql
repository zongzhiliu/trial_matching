/*** match attribute for cancer stage
Requires: cohort, crit_attribute_used, trial_attribute_used
    stage
Results: _p_a_t_stage
*/
drop table if exists _p_a_t_stage cascade;
create table _p_a_t_stage as;
with cau as (
    select attribute_id, code_type, code
    , attribute_value--, attribute_value_norm
    from crit_attribute_used
    where code_type in ('stage_base', 'stage_like')
), tau as (
    select attribute_id, trial_id
    , ie_value
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