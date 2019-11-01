create schema ct_nsclc;
set search_path=ct_nsclc;

alter table demo rename to demo_achieved_20191028;
create table demo as
select d.*
from ct_lca.demo  d
join ct_lca.histology using (person_id)
where histologic_icdo ~ '804[1-5]/3'
	-- and date_of_death is NULL
;
select count(*) from demo;
/****
 * NSCLC
 * Input: cplus_from_aplus, 
 * resource.sema4_msdwpts_deceased_dates_2019_05_07
 */
--create view cohort_filters.v_nsclc_histology as
select histologic_icdo, histologic_type_name, count(*)
from cplus_from_aplus.cancer_diagnoses cd
join prod_references.histologic_types h using (histologic_type_id, cancer_type_id)
join cplus_from_aplus.person_mrns using (person_id)
join cplus_from_aplus.cancer_types using (cancer_type_id)
where cancer_type_name='LCA' and histologic_icdo !~ '804[1-5]/3' --small cell
group by histologic_icdo, histologic_type_name
;

--cohort: use all the histology_types (including lung cancer, unknown) for now, ask for feed back later.
-- person_id, histology, stage, dob, gender
drop table cohort;
create table ct_nsclc.cohort as
	select distinct person_id
	, histologic_icdo, histologic_type_name as histology
	, overall_stage stage
	, regexp_substr(stage, '^(I|II|III|IV)') stage_base
	, regexp_substr(stage, '[A-C].*') stage_ext
	, date_of_birth::date as date_of_birth
	, gender_name gender
	from cplus_from_aplus.cancer_diagnoses cd
	join prod_references.histologic_types h using (histologic_type_id, cancer_type_id)
	join cplus_from_aplus.person_mrns using (person_id)
	join cplus_from_aplus.cancer_types using (cancer_type_id)
    join cplus_from_aplus.people using (person_id)
    join cplus_from_aplus.genders using (gender_id)
	where cancer_type_name='LCA' and histologic_icdo !~ '804[1-5]/3' --small cell
		and date_of_death is null
;
select count(*) from ct_nsclc.cohort;
 -- 3170
select count(distinct person_id) from cohort;
 -- 3068

create table demo as
select distinct person_id, date_of_birth dob, gender
from ct_nsclc.cohort
;



show search_path;
select count(*) from demo;
 -- 3068

-- allowed values for LCA stages
SELECT distinct value
from cplus_from_aplus.accepted_values
where cancer_type_id=1
	and record_type='CancerDiagnosis'
	and attribute_name='overall_stage'
order by value
;

select 0 or 0 or '' in ('a', 'b');
--performance: to be simplified later
create temporary table _last_performance as 
select person_id, ecog_ps, karnofsky_pct
from demo
left join (select *, row_number() over (partition by person_id
	order by performance_score_date desc, ecog_ps)
	from cplus_from_aplus.performance_scores) using (person_id)
where row_number=1 or row_number is null
;

alter table _last_performance add column karnofsky_ps int;
update _last_performance
set karnofsky_ps=tmp.karnofsky_ps
from (select person_id, k.ecog_ps as karnofsky_ps
	from _last_performance
	join cohort_filters.karnofsky_to_ecog k using (karnofsky_pct)
) as tmp
where _last_performance.person_id=tmp.person_id;

alter table _last_performance add column last_performance int;
update _last_performance set last_performance=nvl(ecog_ps, karnofsky_ps)
where true;

select last_performance, count(*) 
from _last_performance
group by last_performance
order by last_performance;

create table last_performance as select * from _last_performance;
select * from last_performance;

-- lot
create table max_lot as
select person_id, mrn, nvl(max(nvl(lot,0)),0) max_lot
from demo
join cplus_from_aplus.person_mrns using (person_id)
left join dev_patient_clinical_lca.line_of_therapy using (mrn)
group by person_id, mrn
;

set search_path=ct_nsclc;
drop table patient_attr;
create table ct_nsclc.patient_attr as
select person_id, histology
, stage
, case stage_base when '' then NULL else stage_base end as stage_base
, case stage_ext when '' then NULL else stage_ext end as stage_ext
, case stage_ext when '' then NULL else stage_base+stage_ext end as stage_full
, '' as status --mock for now
, gender, (datediff(day, date_of_birth, current_date)/365.25)::int age
, last_performance ecog
, nvl(l.max_lot, 0) max_lot
from cohort
left join last_performance using (person_id)
left join max_lot l using (person_id)
;
select * from patient_attr;

select * from max_lot;
select * from _ex_match;

/***
 * Mutations
 */

set search_path=cplus_from_aplus;
select gene, listagg(distinct hgvs_p, ' |') pdot
from variant_occurrences
join target_genes using (target_gene_id)
group by gene
;
select gene, exon, variant_type, listagg(distinct hgvs_p, ' |') pdot
from variant_occurrences
join target_genes using (target_gene_id)
where variant_type != 'SNV' and is_clinically_significant and gene in ('EGFR', 'ERBB2')
group by gene, exon, variant_type
;




select * from _ex_match where person_id=17987;
show search_path;
select NULL+'sd';
create table ct_match (trial_id text, person_id text
, age BOOL
, ecog BOOL
);
insert into ct_match
select 340378 as trial_id, person_id
            , age >= 18 as age
            , ecog BETWEEN 0 and 1 as ecog
            from ct_nsclc._patient_attr
            ;
select case stage_base when '' then NULL else stage_base end stage_base
select stage_base
from patient_attr;

select count(*) from patient_attr;
select * from patient_attr;
-- 3170
create table ct_nsclc.patient_attr as
select * 
, case stage_ext when '' then NULL else stage_base+stage_ext end stage_full
, '' as status  
from ct_nsclc._patient_attr order by person_id;

/***
 * test matching
 */

select person_id
, nvl(age, 0) between 18 and 100 as age
, nvl(ecog, 0) between 0 and 1 as ecog
, nvl(max_lot, 0)>=1 as has_previous_lot
, stage_full between 'IB' and 'IVA' or 'I' < stage_base and stage_base < 'IV'  as stage
  from ct_nsclc.patient_attr
;


select histology, histologic_icdo, count(*)
from ct_nsclc.cohort
group by histology, histologic_icdo
order by histology, histologic_icdo
;
/******
 * Performance
 */
create temporary table _last_performance as 
select mrn, ecog_ps, karnofsky_pct
from _dx
left join (select *, row_number() over (partition by mrn
	order by note_date desc, ecog_ps)
	from performance_scales_ecog) using (mrn)
where row_number=1 or row_number is null
;

alter table _last_performance add column karnofsky_ps int;
update _last_performance
set karnofsky_ps=tmp.karnofsky_ps
from (select mrn, k.ecog_ps as karnofsky_ps
	from _last_performance
	join cohort_filters.karnofsky_to_ecog k using (karnofsky_pct)
) as tmp
where _last_performance.mrn=tmp.mrn;
--select * from _last_performance where ecog_ps is not null and karnofsky_pct is not null;

alter table _last_performance add column last_performance int;
update _last_performance set last_performance=nvl(ecog_ps, karnofsky_ps)
where true;

select last_performance, count(*) 
from _last_performance
group by last_performance
order by last_performance;
drop table cohort_filters.sclc_last_performance;
create table cohort_filters.sclc_last_performance as select * from _last_performance;



/****
 * demo
 */
--select count(distinct mrn)
create table ct_nsclc._demo as
select person_id, gender_name gender, date_of_birth::date birth_date
, floor(datediff(day, birth_date, current_date)/365.25) as age_now
from cplus_from_aplus.people
join _dx using (person_id)
join cplus_from_aplus.genders using (gender_id)
; --3509
select count(*) from _demo;
--create table cohort_filters.nsclc_age as select * from _age;

select ar.name, count(distinct mrn)
from cohort_filters.age_range ar
join _age a
on a.age_now between ar.age_start and ar.age_end
group by ar.name
order by ar.name
;

/***
 * last follow up date: note_date of the last progress note, suggested by meng
 */
create table ct_nsclc._last_followup as
select mrn, max(n.note_date) as last_progress_note_date
from _dx d
join dev_patient_info_lca.notes_v11 n using (mrn)
where note_type_simple='Progress'
group by mrn
;
select count(*) from _last_followup
where datediff(month, last_progress_note_date, current_date) < 12
; --2784, 943



/******
 * Treatment
 */
-- filter by treatment: whether or not intended to treat lung cancer
select mrn, listagg(distinct drugname, ',')
from dev_patient_clinical_lca.line_of_therapy
group by mrn
;
create temporary table _treatment as
select mrn, cancer_drug, age_in_days as last_ageday, modality
from (select *, row_number() over (
		partition by mrn, cancer_drug
		order by age_in_days desc)
	from dev_patient_clinical_lca.cancer_drugs_pt_w_nccn)
join _dx using (mrn)
where row_number=1
; 
select count(distinct mrn) from _treatment; --509

--create table cohort_filters.sclc_treatment as select * from _treatment;
drop table if exists cohort_filters.nsclc_modality;
create table cohort_filters.nsclc_modality as (
	select mrn, modality, count(*)
	from _treatment
	group by mrn, modality
);

-- select count(distinct mrn) from _age;

create view cohort_filters.v_nsclc_modality_pivot as
with _tmp as (
select mrn
, case when modality='chemotherapy' then True else False end as chemotherapy
, case when modality='immunotherapy' then True else False end as immunotherapy
, case when modality='targeted' then True else False end as targeted
from cohort_filters.nsclc_modality
)
select mrn
, bool_or(chemotherapy) chemotherapy
, bool_or(immunotherapy) immunotherapy
, bool_or(targeted) targeted
from _tmp
group by mrn
;
 
/***
 * LOT
 */
drop table if exists _lot;
create TEMPORARY table _lot as
select mrn, drugname, lot, agedays as last_ageday
from (select *, row_number() over (
		partition by mrn, drugname, lot
		order by agedays desc)
	from line_of_therapy)
join _dx using (mrn)
where row_number=1
order by mrn, lot
;
create table cohort_filters.sclc_lot as select * from _lot;
		

/***
 * Biomarkers
 */
-- filter by biomarkers: p53, EGFR, ALK, ROS1, RET fusion, PD-L1 expr, MSI high
drop table if exists _biomarker;
create temporary table _biomarker as
select mrn, lab, gene, max(nvl(positive, '')) as any_positive
from molecular_testing_variants_w_clin_sig_and_additional
join _dx using (mrn)
group by mrn, lab, gene
;  
create table cohort_filters.sclc_biomarker as select * from _biomarker;

select lab, count(distinct mrn)
from molecular_testing_variants_w_clin_sig_and_additional
where gene='KRAS' and positive='YES'
	--and pdot like 'p.G12C' 
group by lab
;

/******
 * Stage
 */
--create table cohort_filters.nsclc_stage as (
create temporary table _stage as
select mrn, person_id, nvl(overall_stage_mapped, imputed_stage_optimized) final_stage
, case when final_stage like 'IV%' then 'IV'
	when final_stage like 'III%' then 'III'
	when final_stage like 'II%' then 'II'
	when final_stage like 'I%' then 'I'
	else final_stage end as base_stage
from imputed_stage
join cplus_from_aplus.person_mrns using (person_id)
where final_stage is not null
;

select base_stage, count(*)
from _dx
left join _stage using (mrn)
group by base_stage
order by base_stage;
--select count(distinct mrn) from _stage join _dx using (mrn) where final_stage is not null;

/****
 * cohort filtering for AMG 510
 */

-- kras
--select lab, count(distinct mrn)
select (gene='KRAS' and positive='YES'
	and pdot='p.G12C') as kras_g12c
	, count(distinct mrn)
from molecular_testing_variants_w_clin_sig_and_additional
group by kras_g12c
;

-- stage + kras
select base_stage in ('III', 'IV') as advanced
, count(distinct mrn)
from _dx
join molecular_testing_variants_w_clin_sig_and_additional using (mrn)
join _stage using (mrn)
where gene='KRAS' and positive='YES'
	and pdot = 'p.G12C' 
group by advanced 
;

-- stage + treatment

/*select (lower(cancer_drug) ~ 'platin'
	or modality='targeted'
	) as p_t_treated, count(distinct mrn)
	*/
select count(distinct mrn)
from _dx cd
join _stage using (mrn)
join _treatment using (mrn)
where base_stage in ('III', 'IV')
	and (lower(cancer_drug) ~ 'platin' or modality='targeted')
--group by p_t_treated
;

-- stage + platin/targeted + kras
--select (gene='KRAS' and positive='YES'
--	and pdot='p.G12C') as kras_g12c
--	, count(distinct mrn)
select count (distinct mrn)
from _dx
join _stage using(mrn)
join _treatment using (mrn)
left join molecular_testing_variants_w_clin_sig_and_additional using (mrn)
where base_stage in ('III', 'IV') 
	and (cancer_drug ilike '%platin' or modality='targeted')
	and (gene='KRAS' and pdot='p.G12C' and positive='YES')
--group by kras_g12c
;

-- final list
drop table if exists _raw;
create TEMPORARY table _raw as
	select mp.*, cd.person_id
	, age_now, ecog_ps, karnofsky_pct
	, last_progress_note_date
	, cancer_dx_date_year || '-' || cancer_dx_date_month || '-' || cancer_dx_date_day as cancer_dx_date
	, dx_date_note_id, histology_note_id, staging_note_id, ptnm_note_id, ctnm_note_id
	, histology, histologic_type_name
	, overall_stage_mapped, final_stage, base_stage
	, gene, pdot, positive
	, last_ageday as _rank
	from _dx cd
	join _age using (mrn)
	join _last_performance using (mrn)
	join _last_followup using (mrn)
	join _stage using (mrn)
	join _treatment using (mrn)
	join cohort_filters.v_nsclc_modality_pivot mp using (mrn)
	join molecular_testing_variants_w_clin_sig_and_additional using (mrn)
	where base_stage in ('III', 'IV')
		and (lower(cancer_drug) ~ 'platin' or modality='targeted')
		and gene='KRAS' and pdot='p.G12C' and positive='YES'
;

drop table if exists cohort_filters.nsclc_final_list_for_amg510 cascade;
create table cohort_filters.nsclc_final_list_for_amg510 as
select *
from (select *, row_number() over(
		partition by mrn
		order by _rank desc)
	from _raw)
where row_number=1
;
create view cohort_filters.v_nsclc_final_list_for_amg510 as
select mrn
, n.note_date ||' '|| n.note_type_simple ||' '|| n.note_id as note_date_type_id
, full_note_pretty
from dev_patient_info_lca.notes_v11 n
join cohort_filters.nsclc_final_list_for_amg510 d using (mrn)
order by mrn, n.note_date
;

drop table cohort_filters.nsclc_amg510_with_brain_met;
--create table cohort_filters.nsclc_amg510_with_brain_met as
with _brain_met as (
	select mrn
	, min(d.dx_date) as first_brain_met_date
	, max(d.dx_date) as last_brain_met_date
	, max(d.context_diagnosis_code) as icd_code
	, max(d.description) as icd_description
	from cohort_filters.nsclc_final_list_for_amg510 p
	join dev_patient_info_lca.all_diagnosis d 
		on p.mrn=d.medical_record_number
	where d.description ilike 'secondary%brain%' --C79.31, 198.3
	group by mrn
)
select p.*, icd_code as brain_met_icd_code
, first_brain_met_date, last_brain_met_date
from cohort_filters.nsclc_final_list_for_amg510 p
left join _brain_met using (mrn)
order by last_progress_note_date desc
;
/***
* RET fusions
*/
select mrn, note_id, substring(full_note, regexp_instr(lower(full_note), '\\Wret\\W')-250, 355), full_note
from pathologies p
where lower(full_note) ~ '\\Wret\\W'
	--and lower(full_note) ~ 'pathlab'
	and lower(full_note) ~ 'rearrangement|fusion'
;
	--all for hotspot

-- from sentences
select mrn, note_id, cohort_filters.context_of('\\Wret\\W', lower(sent_norm), 250), sent_norm
from dev_patient_info_lca.sentences
where lower(sent_norm) ~ '\\Wret\\W'
	and lower(sent_norm) ~ 'arrangement|fusion|\\+'
;
	-- only one patient show in hx 'dx: nsclc for kif5b-ret fusion'
	--stage iv non-small cell lung cancer with an alk arrangement and a ret rearrangement.
	--a history of metastatic alk+ ret+ adenocarcinoma of the lung (malignant pleural effusion)
	-- kif5b-ret fusions
/* so no RET fusion performed at all, check other drivers instead, (should be mutual exclusive) */

-- stage + performance
-- select last_performance<=1 good_performance, count(distinct mrn)
select count (distinct mrn)
from _dx
join _stage using (mrn)
join _last_performance using (mrn)
where base_stage in ('III', 'IV')
--group by good_performance order by good_performance
;

-- stage + platins + performance
/*create temporary table _last_platin_or_others as
select *
from (select *, row_number() over (
		partition by mrn
		order by )
*/
-- select last_performance<=1 good_performance, count(distinct mrn)
select count (distinct mrn)
from _dx
join _stage using (mrn)
join _treatment using (mrn)
join _last_performance using (mrn)
where base_stage in ('III', 'IV')
	--and lower(cancer_drug) ~ 'platin'
--group by good_performance order by good_performance
;

/***
* explore trialtrove
*/
set search_path=cohort_filters;
select datepart(year, primary_completion_date::DATE) pc_year
, count(*)
from ct_nsclc_trialtrove
group by pc_year
order by pc_year;

select datediff(day,  current_date, primary_completion_date::DATE) pc_days_left
from ct_nsclc_trialtrove
where pc_days_left<60
;

/***
* make check boxs
*/
set search_path=ct_nsclc;
create table age_checks as
select person_id, age, age>=12 as age_ge_12, age>=18 as age_ge_18, age>=22 as age_ge_22
from patient_attr
;

drop table stage_checks;
create table stage_checks as
select person_id, stage --, stage_unknown
, stage_base='I' as stage_I, stage_full like 'IA%' as stage_IA, stage_full like 'IB%' as stageIB
, stage_base='II' as stage_II, stage_full like 'IIA%' as stage_IIA, stage_full like 'IIB%' as stage_IIB
, stage_base='III' as stage_III, stage_full like 'IIIA%' as stage_IIIA, stage_full like 'IIIB%' as stage_IIIB, stage_full like 'IIIC%' as stage_IIIC
, stage_base='IV' as stage_IV, stage_full like '%IVA' as stage_IVA, stage_full like '%IVB' as stage_IVB
from patient_attr
;
show search_path;
select * from stage_checks;

create table histology_checks as
select person_id, histology
, True as both, histology in ('Squamous Cell Carcinoma') squamous, histology not in ('Squamous Cell Carcinoma') as non_squamous
from patient_attr
;
select * from histology_checks;

create table ecog_checks as
select person_id, ecog
, ecog=0 as ecog_0, ecog<=1 as ecog_le_1, ecog<=2 as ecog_le_2
from patient_attr
;
select * from ecog_checks;

set search_path=ct_nsclc;
drop table lot_checks;
create table lot_checks as
select person_id, nvl(max_lot, 0) lot
, lot=0 as lot_none, lot>=1 as lot_any, lot=1 as lot_1, lot=2 as lot_2, lot=3 as lot_3, lot>=4 as lot_ge_4
from max_lot
;
select * from lot_checks;
