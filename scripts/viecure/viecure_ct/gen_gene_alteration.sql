create table all_gene_alteration as
select patientid person_id, genelist.name gene_name
, mutation_type.description mutation_type_name
, gene_source_type.description gene_source_type_name
, created_tstamp test_time
, raw_position
, gd.pd_result
, gd.pd_tumor_score_percent
from viecure_emr.patient_gene_details gd
join viecure_emr.patient_gene on patient_gene_id=patient_gene.id
join viecure_emr.genelist on genelist_id=genelist.id
join viecure_emr.mutation_type on mutation_type_id=mutation_type.id
join viecure_emr.gene_source_type on gene_source_type_id=gene_source_type.id
;

create view qc_gene_alteration as
select gene_name, mutation_type_name, gene_source_type_name
 , count(*) records, count(distinct person_id) patients
 from all_gene_alteration
 group by gene_name, mutation_type_name, gene_source_type_name
 order by gene_name, mutation_type_name, gene_source_type_name
 ;
select count(*) records, count(distinct gene_name) genes, count(distinct person_id) patients
from all_gene_alteration;
