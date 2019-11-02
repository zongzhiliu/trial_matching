create schema ct_lca;
set search_path=ct_lca;

/***
 * demo
 */
create table demo as
select distinct person_id, date_of_birth, gender_name, date_of_death, race_name, ethnicity_name
from cplus_from_aplus.cancer_diagnoses cd
--join cplus_from_aplus.cancer_types using (cancer_type_id)
join cplus_from_aplus.people p using (person_id)
join cplus_from_aplus.genders g using (gender_id)
join cplus_from_aplus.races r using (race_id)
join cplus_from_aplus.ethnicities using (ethnicity_id)
where cd.status != 'deleted' and p.status != 'deleted'
	and cancer_type_id=1 --and cancer_type_name='LCA'
;

show search_path;
select * from demo;
select count(*) from demo; 
	--5007

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
where cd.status != 'deleted'
;

create table stage as
select person_id, stage
, case when stage_base='' then NULL else stage_base end stage_base
, case when stage_ext='' then NULL else stage_ext end stage_ext
, case when stage_full='' then NULL else stage_full end stage_full
from _stage
;

drop table if exists stage_checks;
create table stage_checks as
select person_id, stage --, stage_unknown
, stage_base='I' as stage_I
, stage_base='I' and stage_ext like 'A%' as stage_IA
, stage_base='I' and stage_ext like 'B%' as stage_IB
, stage_base='II' as stage_II
, stage_base='II' and stage_ext like 'A%' as stage_IIA
, stage_base='II' and stage_ext like 'B%' as stage_IIB
, stage_base='III' as stage_III
, stage_base='III' and stage_ext like 'A%' as stage_IIIA
, stage_base='III' and stage_ext like 'B%' as stage_IIIB
, stage_base='III' and stage_ext like 'C%' as stage_IIIC
, stage_base='IV' as stage_IV
, stage_base='IV' and stage_ext like 'A%' as stage_IVA
, stage_base='IV' and stage_ext like 'B%' as stage_IVB
from stage
;
select * from stage_checks limit 10;

/***
* labs
*/
-- using prod_msdw.all_labs
-- config: the loinc codes needed
-- config later: the normal range
-- later: convert to ULM


select *
from prod_msdw.all_labs
join demo using (person_id)
limit 10;

set search_path=ct_lca;
select *
from ct.reference_NSCLC_lab_test
left join _all_loinc using (loinc_code)
;

create table labs as
select distinct person_id, result_date::date, loinc_code, loinc_display_name, value_float, value_range_low, value_range_high, unit
, source_value, source_unit
from _all_labs a
join ct.reference_nsclc_lab_test using (loinc_code)
where value_float is not null
;

select * from ct_lca.labs order by person_id, result_date, loinc_code, value_float, source_value, source_unit;
show search_path;
select * from labs;

create table last_lab as
select person_id, result_date as last_date, loinc_code, loinc_display_name, value_float, unit
from (select *, row_number() over (
		partition by person_id, loinc_code
		order by result_date desc nulls last, value_float desc nulls last)
		from labs)
where row_number=1
order by person_id, last_date, loinc_code
;

--create table last_lab_pivot as
select person_id
, max(case when loinc_code='1920-8' then value_float end lab_ast
, case when loinc_code='1742-6' then value_float end lab_alt
, case when loinc_code='1975-2' then value_float end lab_total_bilirubin
, case when loinc_code='1968-7' then value_float end lab_direct_bilirubin
, case when loinc_code='2160-0' then value_float end lab_serum_creatinine
, case when loinc_code='2164-2' then value_float end lab_crcl
, case when loinc_code='773-2' then value_float end lab_platelets
, case when loinc_code='26499-4' then value_float end lab_anc
, case when loinc_code='718-7' then value_float end lab_hemoglobin
, case when loinc_code='26464-8' then value_float end lab_wbc
from last_lab
GROUP BY person_id
order by person_id
;

select * from histology_checks;

set search_path=ct_lca;
select *
from (select *, row_number() over (partition by stage
        order by person_id)
    from stage_checks)
where row_number=1
order by stage
;

select *
from (select *, row_number() over (partition by histology
        order by person_id)
    from histology_checks)
where row_number=1
order by histology
;


/***
* mutations
*/
set search_path=ct_lca;
drop table if exists ct_lca._variant_significant;
create table ct_lca._variant_significant as
select distinct person_id, tissue_collection_date
, genetic_test_name, gene
, variant_type, alteration --, exon
from cplus_from_aplus.variant_occurrences vo
join cplus_from_aplus.genetic_test_occurrences_2019_10_28 using (genetic_test_occurrence_id)
join cplus_from_aplus.genetic_tests_2019_10_28 using (genetic_test_id)
join cplus_from_aplus.target_genes_2019_10_28 using (target_gene_id, genetic_test_id)
join cplus_from_aplus.pathologies p using (pathology_id)
join ct_lca.demo using (person_id)
where is_clinically_significant
	and p.status != 'deleted'  -- all 'not_reviewed'
;
select count(*) from ct_lca._variant_significant; --1761

show search_path;
select gene,  alteration, count(distinct person_id) --* --distinct variant_type, alteration --, exon 
from ct_lca._variant_significant 
where gene in ('EGFR', 'BRAF', 'KRAS', 'ERBB2', 'MET') --'ALK', 'ROS', 'RET'
group by gene, alteration
;
select distinct person_id
from ct_lca._variant_significant
where gene = 'KRAS' and alteration ~ 'p.G12[A-Z]|Codon 12 '

--where gene='ALK'
--where gene='BRAF' and alteration like 'p.V600%'
;
select * from ct_lca._variant_significant;

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

select * from ct_lca._variant_listedgene_pivot;

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

select distinct histology, sclc, nsclc, squamous, non_squamous
from ct_lca.histology_checks
;

CREATE TABLE IF NOT EXISTS ct.lca_histology_mapping
(
	histology VARCHAR(256)
	,sclc bool
	,nsclc bool
	,squamous bool
	,non_squamous bool
	,note varchar
)
;


select *
from (select distinct lower(drug_name) drug_name, category
	from resource.all_cancer_drugs_list_2019_10_07) ac
left join ct.tmp_cancer_drug_category_flat1 using (drug_name)
;
select * from resource.all_cancer_drugs_list_2019_10_07;

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
select * from lot_drug;

create table ct.lca_lot_drug_moa_flat as
select * from
(select distinct(drugname) drug_name from lot_drug)
left join
ct.all_cancer_drug_moa_flat_y using (drug_name)
;

create table ct.lca_lot_drug_category as
select drug_name, modality, moa
, moa ~ 'PD_1' as pd_1
, moa ~ 'PD_L' as pd_l
, moa ~ 'CTLA_4' as ctla_4
-- immune: no IL, OX_40
, moa ~ 'EGFR_' as egfr
, moa ~ 'ALK_' as alk
, moa ~ 'ROS1_' as ros
-- targeted: no PARP, RET, MET
from ct.lca_lot_drug_moa_flat
;

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
select * from p_lot_drugs;
