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
), var as (
    select person_id, gene_name gene
    , decode(mutation_type_name
        , 'Mutation', 'molecular'
        , 'Splice Site', 'splice'
        , 'Copy Number Loss', 'cnv'
        , mutation_type_name) variant_type
    , 'p.'+ replace(replace(replace(replace(replace(replace(replace(raw_position
        , 'Leu', 'L')
        , 'Gly', 'G')
        , 'Val', 'V')
        , 'Arg', 'R')
        , 'Lys', 'K')
        , 'Cys', 'S')
        , 'Glu', 'E') as variant --quickfix
    from viecure_ct.all_gene_alteration
)
select person_id, attribute_id
, bool_or(case code_type
    when 'gene_variant' then ct.py_contains(nvl(variant, ''), code_ext)
    when 'gene_display' then ct.py_contains(nvl(variant_type, ''), code_ext, 'i') --quickfix
    when 'gene_vtype' then ct.py_contains(nvl(variant_type, ''), code_ext, 'i') --quickfix
    when 'gene_rtype' then ct.py_contains(nvl(variant_type, ''), code_ext, 'i') --quickfix
    end) as match
from var
join cau on ct.py_contains(gene, cau.code)
group by person_id, attribute_id, code_type, code, code_ext
;

create view qc_match_variant as
with tmp as (
    select attribute_id
    , count(distinct person_id) patients
    from _p_a_variant
    where match
    group by attribute_id
)
select attribute_id, attribute_name, code, code_ext
, patients as match_patients
from crit_attribute_used
left join tmp using (attribute_id)
where code_type like 'gene_%'
order by attribute_id
;
select * from qc_match_variant;
