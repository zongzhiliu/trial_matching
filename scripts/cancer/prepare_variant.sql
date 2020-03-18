/***
* mutations
*/
drop table if exists _variant_significant cascade;
create table _variant_significant as
select person_id, genetic_test_name, gene
, variant_type
, case when variant in ('Not Reported') then null else variant
    end variant
, reported_occurrence_type
from cohort
join cplus_from_aplus.genetic_test_occurrences using (person_id)
join cplus_from_aplus.genetic_tests using (genetic_test_id)
join cplus_from_aplus.variant_occurrences using (genetic_test_occurrence_id)
join cplus_from_aplus.target_genes using (target_gene_id) --, genetic_test_id)
where is_clinically_significant
;
/*old
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
*/
