set search_path=zach_testing;

--NRG1 alteration in lung and other cancer
create view oncsuite_variants_goi as
with olung as (
	select *
    from oncsuite.variants_reported_all
	where True --sample_site='Thyroid'
		and gene ~ '^(NRG1|RET)'
)
select gene, sample_site, oncotree_code, is_clinically_significant
, report_type, variant_type, variant
, first_published, mrn
, person_id, cancer_type_name, cd.overall_stage, cd.status
from olung
left join prod_references.person_mrns using (mrn)
left join cplus_from_aplus.cancer_diagnoses cd using (person_id)
left join prod_references.cancer_types using (cancer_type_id)
order by gene, sample_site, oncotree_code, is_clinically_significant desc
, report_type, variant_type, variant
, person_id, mrn
;

drop view qc_oncsuite_variants;
create view qc_oncsuite_variants as
with stratified as (
    select NULL::varchar as "__"
    , sample_site, oncotree_code
    , count(*) records, count(distinct gene) genes, count(distinct mrn) patients
    from oncsuite.variants_reported_all
    group by sample_site, oncotree_code
    order by sample_site, oncotree_code
), total as (
    select '__total', count(distinct sample_site)::varchar, count(distinct oncotree_code)::varchar
    , count(*) records, count(distinct gene) genes, count(distinct mrn) patients
    from oncsuite.variants_reported_all
), res as (
    select * from stratified union all
    select * from total
)
select * from res
order by __ desc, sample_site, oncotree_code
;

--drop view qc_oncsuite_variants;
create view qc_oncsuite_variants_type as
select  gene, sample_site, oncotree_code, report_type
    , count(distinct mrn) patients
from oncsuite.variants_reported_all
group by  gene, sample_site, oncotree_code, report_type
order by  gene, sample_site, oncotree_code, report_type
;

