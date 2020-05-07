/*** match attribute for alteration/variants
Requires: crit_attribute_used
    _variant_significant
Results: _p_a_variant
*/
drop table if exists _p_a_variant cascade;
create table _p_a_variant as
with cau as (
    select attribute_id, code_type, code, code_ext
    from crit_attribute_used
    where code_type like 'gene%'
)
select person_id, attribute_id
, bool_or(case code_type
    when 'gene_variant' then ct.py_contains(nvl(variant, ''), code_ext) --quickfix
    when 'gene_display' then ct.py_contains(nvl(variant_display_name, ''), code_ext) --quickfix
    when 'gene_vtype' then lower(variant_type) = lower(code_ext) --quickfix
    when 'gene_rtype' then ct.py_contains(nvl(reported_occurrence_type, ''), code_ext, 'i') --quickfix
    end) as match
from _variant_significant
join cau on ct.py_contains(gene, cau.code)
group by person_id, attribute_id, code_type, code, code_ext
;

create view qc_match_variant as
select attribute_id, attribute_name, code, code_ext
, count(distinct person_id) patients
from _p_a_variant
join crit_attribute_used using (attribute_id)
where match
group by attribute_id, attribute_name, code, code_ext
order by attribute_id
;
select * from qc_match_variant;
