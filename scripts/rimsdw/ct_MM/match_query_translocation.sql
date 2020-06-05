/* > pa_transloaction
Input: cohort, oncsuite
*/

drop table if exists _p_a_translocation cascade;
create table _p_a_translocation as
with a as (
    select * from crit_attribute_used
    where code_type='query_translocation' and code='genomic_location'
), chrs as (
    select person_id, collection_date
    , is_clinically_significant
    , regexp_replace(genomic_location, '^chr([^:]+):.*$', '$1') chr_left
    , regexp_replace(genomic_location, '^.*/chr([^:]+):.*$', '$1') chr_right
    from oncsuite.variants_fusion
    join prod_references.person_mrns using (mrn)
    join cohort using (person_id)
)
select person_id, attribute_id
    , bool_or(case code_ext
        when 't(9;22), t(1;19), t(4;11)' then
            (chr_left in ('9', '22') and chr_right in ('9', '22'))
            or
            (chr_left in ('1', '19') and chr_right in ('1', '19'))
            or
            (chr_left in ('4', '11') and chr_right in ('4', '11'))
       when 't(14;16), t(14;20)' then
            (chr_left in ('14', '16') and chr_right in ('14', '16'))
            or
            (chr_left in ('14', '20') and chr_right in ('14', '20'))
       end) as match
from a cross join chrs
group by person_id, attribute_id
;

create view qc_match_translocation as
select attribute_id, attribute_name, attribute_value
, count(distinct person_id)
from _p_a_translocation
join crit_attribute_used using (attribute_id)
where match
group by attribute_id, attribute_name, attribute_value
;
select * from qc_match_translocation;;

