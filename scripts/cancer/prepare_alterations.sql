/***
* mutations
*/
/** not working yet
create table tmp_variant_significant as
select distinct person_id, tissue_collection_date::date
, genetic_test_name, gene
, variant_type, alteration
from demo
join cplus_from_aplus.genetic_test_occurrences using (person_id)
join cplus_from_aplus.genetic_tests using (genetic_test_id)
join cplus_from_aplus.variant_occurrences vo using (genetic_test_occurrence_id)
join cplus_from_aplus.target_genes using (target_gene_id)
where is_clinically_significant
;
*/
create table _variant_significant as
select distinct person_id, tissue_collection_date
, genetic_test_name, gene
, variant_type, alteration --, exon
from cplus_from_aplus.variant_occurrences vo
join cplus_from_aplus.genetic_test_occurrences using (genetic_test_occurrence_id)
join cplus_from_aplus.genetic_tests using (genetic_test_id)
join cplus_from_aplus.target_genes using (target_gene_id, genetic_test_id)
join cplus_from_aplus.pathologies p using (pathology_id)
join demo using (person_id)
where is_clinically_significant
    and nvl(p.status, '') != 'deleted'

create table gene_alterations as
select person_id, gene
, listagg(distinct alteration , '|') within group (order by alteration) as alterations
from _variant_significant
group by person_id, gene
;


