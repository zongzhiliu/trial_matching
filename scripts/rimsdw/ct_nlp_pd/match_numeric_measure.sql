/*** match attribute using numeric_measure code
Requires: crit_attribute_used, 
    numeric_measure
Results: _p_a_numeric_measurement
*/
drop table if exists _p_a_numeric_measurement cascade;
create table _p_a_numeric_measurement as
with cau as (
    select attribute_id, code
    , regexp_substr(attribute_value, '[0-9]+')::float code_value
    , code_ext, code_transform
    from crit_attribute_used
    where code_type = 'numeric_measurement'
)
select person_id, attribute_id, code
, case code_ext
    when 'ge' then value_float * code_transform >= code_value
    when 'eq' then value_float * code_transform = code_value
    end as match
from numeric_measurement
join cau using (code)
;
