/*** match attribute using loinc codes
Requires: crit_attribute_used
    latest_lab
Results: _p_a_loinc
*/
drop table if exists _p_a_loinc cascade;
create table _p_a_loinc as
with cau as (
    select attribute_id, code_type, code lab_test_name
    , regexp_substr(attribute_value, '[0-9]+([.][0-9]+)?')::float crit_value
    , code_ext as comp
    , code_transform
    from crit_attribute_used
    where code_type = 'loinc_mapping'
)
select person_id, attribute_id
, case when code_transform='/normal_high' then
        1/normal_high::float --quickfix
    when code_transform='/normal_low' then
        1/normal_low::float
    else code_transform::float
    end as p2c_factor
, case when lower(comp) in ('min', 'ge', '>=', '>') then
        value_float * p2c_factor >= crit_value
    when lower(comp) in ('max', 'le', '<=', '<') then
        value_float * p2c_factor <= crit_value
    when lower(comp) in ('eq', '=') then
        value_float * p2c_factor = crit_value
    end as match
from cohort join latest_lab using (person_id)
join ref_lab_mapping using (loinc_code)
join cau using (lab_test_name)
;

create view qc_match_loinc as
with tmp as (
    select attribute_name, attribute_value, match
    , count(distinct person_id)
    from _p_a_loinc
    join crit_attribute_used using (attribute_id)
    group by attribute_name, attribute_value, match
)
select attribute_name, attribute_value
, sum(case when match is True then count end) patients_true
, sum(case when match is False then count end) patients_false
, sum(case when match is Null then count end) patients_null
from tmp
group by attribute_name, attribute_value
order by attribute_name, attribute_value
;
select * from qc_match_loinc;
