drop table if exists _p_a_t_biomarker;
CREATE TABLE _p_a_t_biomarker as
with cau as (
    SELECT attribute_id, attribute_value, code_type, code
    from ct_bca.crit_attribute_used
    WHERE code_type = 'protein_biomarker'
    --WHERE attribute_id ~ 'BCA4[78]'
), tau as (
    SELECT trial_id, attribute_id,
    nvl(inclusion, exclusion)::float marker_level
    from ct_bca.trial_attribute_used
)
SELECT person_id, trial_id, attribute_id
, marker_level as ie_value
, bool_or(case lower(attribute_value)
    when 'max' THEN positive_cell_pct * 100 <= marker_level
    when 'min' THEN positive_cell_pct * 100 >= marker_level
    end) as match
from biomarker b
join cau on b.protein_biomarker_name=cau.code
join tau using (attribute_id)
group by person_id, trial_id, attribute_id, ie_value
;
/*
select attribute_id, attribute_name, attribute_value, ie_value, match
, count(distinct person_id)
from _p_a_t_biomarker join crit_attribute_used using (attribute_id)
group by attribute_id, attribute_name, attribute_value, ie_value, match
;
*/
