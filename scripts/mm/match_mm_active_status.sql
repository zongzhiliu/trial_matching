/***
Result: _p_a_t_mm_active_status
Input: cplus_from_aplus.cancer_diagnosis_mm.mm_active_status
*/
drop table if exists _p_a_t_mm_active_status cascade;
create table _p_a_t_mm_active_status as
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
select person_id, trial_id, attribute_id
, match
from latest_lab
join cau on code=loinc_code
join tau using (attribute_id)
;

