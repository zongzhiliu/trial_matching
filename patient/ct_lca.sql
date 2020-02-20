/***
 * create the patient info tables from Lung cancer LCA patients from cplus if possible
 * 2020-02-18 refresh
 */
--create schema ct_lca;
set search_path=ct_lca;
show search_path;

/***
create table attribute as
select * from ct.attribute
where attribute_id between 1 and 204
; */

/***
 * demo
 */
drop if exists table demo;
create table demo as
select distinct person_id, date_of_birth, gender_name, date_of_death, race_name, ethnicity_name
--select count(*)
from cplus_from_aplus.cancer_diagnoses cd
join cplus_from_aplus.cancer_types using (cancer_type_id)
join prod_references.people p using (person_id)
join prod_references.genders g using (gender_id)
join prod_references.races r using (race_id)
join prod_references.ethnicities using (ethnicity_id)
where nvl(cd.status, '') != 'deleted' and nvl(p.status, '') != 'deleted' --fixed with nvl
	and cancer_type_name='LCA'
;

--select count(*) from demo; 
	--5007 --5614

/***
 * stage: 
 */
create temporary table _stage as
select person_id, overall_stage stage
	, regexp_substr(stage, '^[0IV]+') stage_base
	, regexp_substr(stage, '[A-C].*') stage_ext
	, regexp_substr(stage, '^[0IV]+[A-C].*') stage_full
from demo
left join cplus_from_aplus.cancer_diagnoses cd using (person_id)
where nvl(cd.status, '') != 'deleted'
;
drop table stage cascade;
create table stage as
select person_id, stage
, case when stage_base='' then NULL else stage_base end stage_base
, case when stage_ext='' then NULL else stage_ext end stage_ext
, case when stage_full='' then NULL else stage_full end stage_full
from _stage
;


/***
 * vital
 */

create table vital as
select distinct person_id
	, age_in_days
    , procedure_role
    , procedure_description
    , context_procedure_code
    , context_name
    , value
    , unit_of_measure
from demo 
join prod_references.person_mrns using (person_id)
join dev_patient_info_lca.vitals on (medical_record_number=mrn) --{cancer_type}
;
--select count(distinct person_id) from vital; -- 5310


/***
 * performance: no conversions
 */
create table latest_ecog as 
select person_id, ecog_ps
, performance_score_date::date as performance_score_date
from (select *, row_number() over (
		partition by person_id
		order by performance_score_date desc nulls last, ecog_ps) --tie-breaker: best performance
	from cplus_from_aplus.performance_scores
	join demo using (person_id)
	where ecog_ps is not null)
where row_number=1 
;

create table latest_karnofsky as 
select person_id, karnofsky_pct
, performance_score_date::date as performance_score_date
from (select *, row_number() over (
		partition by person_id
		order by performance_score_date desc nulls last, -karnofsky_pct) --tie-breaker: best performance
	from cplus_from_aplus.performance_scores
	join demo using (person_id)
	where karnofsky_pct is not null)
where row_number=1 
;

/***
* mutations
*/
/** not working yet
create table _variant_significant as
select distinct person_id, tissue_collection_date::date
, genetic_test_name, gene
, variant_type, alteration --, exon
select count(*) --distinct person_id)
from demo
join cplus_from_aplus.genetic_test_occurrences using (person_id) --1951
join cplus_from_aplus.genetic_tests using (genetic_test_id) --1162 from prod_ref, 1725 from cplus
join cplus_from_aplus.variant_occurrences vo using (genetic_test_occurrence_id) -- 22! 35 w/o genetic_test_id
join cplus_from_aplus.target_genes using (target_gene_id) -- genetic_test_id unnecessary for join
where is_clinically_significant
;
*/
create table ct_lca._variant_significant as
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
;
select count(*) from ct_lca._variant_significant; --1761

create table gene_alterations as
select person_id, gene
, listagg(distinct alteration , '|') within group (order by alteration) as alterations
from _variant_significant
group by person_id, gene
;


/*old
create table ct_lca._variant_listedgene as
select person_id, gene
, listagg(distinct alteration , '|') within group (order by alteration) as alterations
from ct_lca.demo
join ct_lca._variant_significant using (person_id)
where gene in ('EGFR', 'BRAF', 'KRAS', 'ERBB2', 'MET', 'ALK', 'ROS','RET')
group by person_id, gene
;

create table ct_lca._variant_listedgene_pivot as
select person_id
, max(case when gene='EGFR' then alterations end) as EGFR
, max(case when gene='KRAS' then alterations end) as KRAS
, max(case when gene='BRAF' then alterations end) as BRAF
, max(case when gene='ERBB2' then alterations end) as ERBB2
, max(case when gene='MET' then alterations end) as MET
, max(case when gene='ALK' then alterations end) as ALK
, max(case when gene='ROS' then alterations end) as ROS
, max(case when gene='RET' then alterations end) as RET
from ct_lca._variant_listedgene
group by person_id
;
*/
-- select * from ct_lca._variant_listedgene_pivot;
/*
-- make the checkboxes for all alterations
create table ct_lca.variant_listedgene_checks as
select person_id
, egfr is not NULL EGFR_any, egfr ~ 'Exon 19 Deletion' EGFR_exon19del
, egfr ~ 'p.L858R' EGFR_L858R, egfr ~ 'p.T790M' EGFR_T790M
, KRAS is not NULL KRAS_any, KRAS ~ 'p.G12\\D|Codon 12 ' KRAS_G12
, BRAF is not NULL BRAF_any, BRAF ~ 'p.V600\\D' BRAF_V600
, MET is not NULL MET_any
, ERBB2 is not NULL ERBB2_any
, ALK is not NULL ALK_any, ALK ~ 'Fusion' ALK_fusion
, ROS is not NULL ROS_any, ROS ~ 'Fusion' ROS_fusion
, RET is not NULL RET_any, RET ~ 'Fusion' RET_fusion
from ct_lca._variant_listedgene_pivot
;
select * from ct_lca.variant_listedgene_checks;
select distinct gene, alteration from ct_lca._variant_significant where genetic_test_name = 'Pathlab';
select True or NULL;
*/

/***
 * biomarker: pd_l1

--select distinct protein_biomarker_name, assay, interpretation
select count(distinct person_id)
from cplus_from_aplus.protein_biomarkers
join cplus_from_aplus.pathologies using (pathology_id, person_id)
;
-- 616 persons in total
-- only 23 (3%) can be mapped to a pathology note?!

-- however all records have a patholgy_id
select pathology_id is null, count(*)
from cplus_from_aplus.protein_biomarkers
group by pathology_id is null
;

--create table ct_lca.p_latest_pd_l as
select person_id, interpretation
, positive_cell_pct, positive_cell_pct_source_value
, intensity_score
from (select *, row_number() over (
		partition by person_id
		order by tissue_collection_date desc nulls last, protein_biomarker_id)
	from cplus_from_aplus.protein_biomarkers b
	join cplus_from_aplus.pathologies p using (pathology_id, person_id)
	where p.status != 'deleted' and b.status != 'deleted')
where row_number=1
;
*/

/***
* diseases
*/
create table ct_lca._all_dx as
select person_id, dx_date, icd, icd_code, description
from (select medical_record_number mrn, dx_date
, icd, context_diagnosis_code icd_code, description
from dev_patient_info_lca.all_diagnosis) d
join cplus_from_aplus.person_mrns using (mrn)
join ct_lca.demo using (person_id)
;

drop table if exists latest_icd;
create table latest_icd as
select person_id, icd_code, icd as context_name, description, dx_date
from (select *, row_number() over (
		partition by person_id, icd_code
		order by dx_date desc nulls last, description)
	from _all_dx
	--where context_name ilike 'ICD%'
	)
where row_number=1
;
--select * from latest_icd;

/*
drop table if exists ct_lca._icd_10;
create table ct_lca._icd_10 as
select distinct icd_code, description
from ct_lca._all_dx
where icd='ICD-10' and description !='NOT AVAILABLE' and description != icd_code;

--6177, 6177
select count(*), count(distinct icd_code) from ct_lca._icd_10;
select * 
from ct_lca._icd_10 
where lower(description) ~
--'secondary.*brain'
--'meninges'
--'spinal cord' -- no
--'lepto meningeal'
--'hiv'
--'tuberculosis'
'hepatitis.*'
order by icd_code;
*/

/***
* lot: including mrn deduplicate
*/
create temporary table _lot as
select person_id, mrn, nvl(max(nvl(lot,0)),0) n_lot
from demo
join cplus_from_aplus.person_mrns using (person_id)
left join dev_patient_clinical_lca.line_of_therapy using (mrn)
group by person_id, mrn
;
-- 5028, 5007, 5007
--select count(*), count(distinct person_id), count (distinct person_id::text + '|' + 'n_lot') from lot;

drop table if exists lot;
create table lot as
select distinct person_id, n_lot
from _lot
;

/***
* lot drugs
*/
show search_path;
create table lot_drug as
select person_id, drugname, max(agedays) as last_ageday
from dev_patient_clinical_lca.line_of_therapy
join cplus_from_aplus.person_mrns using (mrn)
where lot>=1
group by person_id, drugname
;
--select * from lot_drug;


drop table if exists p_lot_drugs;
create table p_lot_drugs as
select person_id, listagg(distinct drug_name, '| ') within group (order by drug_name) as lot_drugs
, bool_or(modality ilike 'chemotherapy%') chemo
, bool_or(drug_name ilike '%platin') platin
, bool_or(modality ilike '%immunotherapy%') immuno
, bool_or(pd_1) pd_1
, bool_or(pd_l) pd_l
, bool_or(ctla_4) ctla_4
, bool_or(modality ilike '%targeted%') targeted
, bool_or(egfr) egfr
, bool_or(alk) alk
, bool_or(ros) ros
from lot_drug h
join ct.lca_lot_drug_category m using (drug_name)
group by person_id
;
--select * from p_lot_drugs;

