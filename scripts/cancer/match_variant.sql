/*** match attribute for alteration/variants
Requires: cohort, crit_attribute_used, trial_attribute_used
    _variant_significant
Results: _p_a_t_variant
*/
drop table if exists _p_a_t_variant cascade;
create table _p_a_t_variant as
with cau as (
    select attribute_id, code_type, code, code_ext
    , attribute_value, attribute_value_norm
    from crit_attribute_used
    where code_type in ('gene_variant', 'gene_vtype', 'gene_rtype')
), tau as (
    select attribute_id, trial_id
    , nvl(inclusion, exclusion) ie_value
    from trial_attribute_used
    --where ie_value = 'yes'
)
select person_id, trial_id, attribute_id
, bool_or(case code_type
    when 'gene_variant' then ct.py_contains(variant, code_ext)
    when 'gene_vtype' then lower(variant_type) = lower(code_ext)
    when 'gene_rtype' then lower(reported_occurrence_type) = lower(code_ext)
    end) as match
from _variant_significant vs
join cau on ct.py_contains(vs.gene, cau.code)
join tau using (attribute_id)
group by person_id, trial_id, attribute_id, code_type, code, code_ext
;
/*
select attribute_id, attribute_name, code, code_ext, match
, count(distinct person_id) patients
from _p_a_t_variant
join crit_attribute_used using (attribute_id)
where match
group by attribute_id, attribute_name, code, code_ext, match
order by attribute_id
;
*/
