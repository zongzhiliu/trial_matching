create table viecure_ct.all_tumor_marker as
select pt_id person_id
, name test_name
, created_tstamp test_time
, positive_ind
, inactive, errored
from patient_tumor_markers  -- 259	96
join tumor_marker_list tml on tumor_marker_id=tml.id --good
where not nvl(inactive, False) 
    and not nvl(errored, False)
;

set search_path=viecure_emr;
create table viecure_ct.all_gene_alteration as
select patientid person_id, genelist.name gene_name
, mutation_type.description mutation_type_name
, gene_source_type.description gene_source_type_name
, created_tstamp test_time
, raw_position
, gd.pd_result
, gd.pd_tumor_score_percent
from patient_gene_details gd
join patient_gene on patient_gene_id=patient_gene.id
join genelist on genelist_id=genelist.id
join mutation_type on mutation_type_id=mutation_type.id
join gene_source_type on gene_source_type_id=gene_source_type.id
;
