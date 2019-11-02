/***
 * patient_attribute_stage
 */
drop table if exists ct_lca.patient_attribute_stage;
create table ct_lca.patient_attribute_stage as
select person_id, stage as patient_value
, attribute_id, attribute_group, attribute_name, value
, case value when 'NA' then NULL
	 when '0' then stage_base='0'
	 when 'I' then stage_base='I'
	 when 'IA' then stage_base='I' and stage_ext like 'A%'
	 when 'IB' then stage_base='I' and stage_ext like 'B%'
	 when 'II' then stage_base='II'
	 when 'IIA' then stage_base='II' and stage_ext like 'A%'
	 when 'IIB' then stage_base='II' and stage_ext like 'B%' 
	 when 'III' then stage_base='III'
	 when 'IIIA' then stage_base='III' and stage_ext like 'A%'
	 when 'IIIB' then stage_base='III' and stage_ext like 'B%' 
	 when 'IV' then stage_base='IV'
	 when 'IVA' then stage_base='IV' and stage_ext like 'A%'
	 when 'IVB' then stage_base='IV' and stage_ext like 'B%'
	end as match
from ct_lca.stage
cross join ct_lca.attribute
where attribute_group='stage' --and attribute_name='stage'
;

select * from ct_lca.patient_attribute_stage;
select True and Null;
select False and null;

/***
* mutations
*/
-- make patient atrribute match
drop table if exists ct_lca.patient_attribute_mutation_EGFR;
create table ct_lca.patient_attribute_mutation_EGFR as
select person_id, egfr as patient_value
, attribute_id, attribute_group, attribute_name, value
, case value when 'exon19 deletion' then egfr ~ 'Exon 19 Deletion'
	when 'L858R' then egfr ~ 'p.L858R'
	when 'T790M' then egfr ~ 'p.T790M'
	when 'yes' then egfr is not NULL
	end as match
from ct_lca._variant_listedgene_pivot
cross join ct_lca.attribute
where attribute_group='mutation' and attribute_name='EGFR'
;

drop table if exists ct_lca.patient_attribute_mutation_KRAS;
create table ct_lca.patient_attribute_mutation_KRAS as
select person_id, KRAS as patient_value
, attribute_id, attribute_group, attribute_name, value
, case value when 'yes' then KRAS is not NULL
	when 'G12' then KRAS ~ 'p.G12\\D|Codon 12 '
	end as match
from ct_lca._variant_listedgene_pivot
cross join ct_lca.attribute
where attribute_group='mutation' and attribute_name='KRAS'
;

drop table if exists ct_lca.patient_attribute_mutation_BRAF;
create table ct_lca.patient_attribute_mutation_BRAF as
select person_id, BRAF as patient_value
, attribute_id, attribute_group, attribute_name, value
, case value when 'yes' then BRAF is not NULL
	when 'V600' then BRAF ~ 'p.V600\\D'
	end as match
from ct_lca._variant_listedgene_pivot
cross join ct_lca.attribute
where attribute_group='mutation' and attribute_name='BRAF'
;

drop table if exists ct_lca.patient_attribute_mutation_HER2;
create table ct_lca.patient_attribute_mutation_HER2 as
select person_id, ERBB2 as patient_value
, attribute_id, attribute_group, attribute_name, value
, case value when 'yes' then ERBB2 is not NULL
	end as match
from ct_lca._variant_listedgene_pivot
cross join ct_lca.attribute
where attribute_group='mutation' and attribute_name='HER2'
;

drop table if exists ct_lca.patient_attribute_mutation_ALK;
create table ct_lca.patient_attribute_mutation_ALK as
select person_id, ALK as patient_value
, attribute_id, attribute_group, attribute_name, value
, case value when 'yes' then lower(ALK) ~ 'fusion'
	end as match
from ct_lca._variant_listedgene_pivot
cross join ct_lca.attribute
where attribute_group='mutation' and attribute_name='ALK fusion'
;

drop table if exists ct_lca.patient_attribute_mutation_ROS;
create table ct_lca.patient_attribute_mutation_ROS as
select person_id, ROS as patient_value
, attribute_id, attribute_group, attribute_name, value
, case value when 'yes' then lower(ROS) ~ 'fusion'
	end as match
from ct_lca._variant_listedgene_pivot
cross join ct_lca.attribute
where attribute_group='mutation' and attribute_name='ROS1 fusion'
;

/***
 * line_of_therapy
 */
set search_path=ct_lca;
create table patient_attribute_lot as
select person_id, n_lot as patient_value
, attribute_id, attribute_group, attribute_name, value
, case value when '0' then n_lot=0
    when '1' then n_lot=1
    when '2' then n_lot=2
    when '3' then n_lot=3
    when '>=4' then n_lot>=4
    end as match
from lot
cross join attribute
where attribute_group='line of therapy'
;
-- check
select *
from (select *, row_number() over (partition by n_lot
        order by person_id)
    from lot_checks)
where row_number=1
order by n_lot
;



/***
* age from wen's age_of_now
*/
select distinct age_of_now from ct_nsclc.patient_demo;
set search_path=ct_lca;
create table patient_attribute_age as
select person_id, age_of_now as patient_value
, attribute_id, attribute_group, attribute_name, value
, case value 
    when '>=12' then patient_value >=12
    when '>=18' then patient_value >=18
    when '>=20' then patient_value >=20
    when '<=70' then patient_value <=70
    end as match
from ct_nsclc.patient_demo
cross join attribute
where attribute_group='age'
;

/*** 
* ecog from wen's ecog_final
*/
select distinct ecog_latest from ct_nsclc.demo_lca_ecog_final;
set search_path=ct_lca;
create table patient_attribute_ecog as
select person_id, ecog_latest as patient_value
, attribute_id, attribute_group, attribute_name, value
, case value 
	when '0' then patient_value =0
    when '1' then patient_value =1
    when '2' then patient_value =2
    when '3' then patient_value =3
    when '4' then patient_value =4
    when '5' then patient_value =5
    end as match
from ct_nsclc.demo_lca_ecog_final
cross join attribute
where attribute_group='ecog'
;
show search_path;

/***
 * lab from wen's nsclc.person_lab_attribute_mapping
 */
select * from ct_nsclc.person_lab_attribute_mapping;
create table patient_attribute_lab as
select person_id, value_to_compare as patient_value
, attribute_id, attribute_group, attribute_name, value_rule as value
, meet_attribute_rule as match
from ct_nsclc.person_lab_attribute_mapping
join attribute using (attribute_id)
;

/***
 * histology checks
 */
set search_path=ct_lca;
select * from histology join ct.lca_histology_category using (histology)
;
create table patient_attribute_histology as
select person_id, h.histology as patient_value
, attribute_id, attribute_group, attribute_name, value
, case value 
	when 'yes' then nsclc
	when 'squamous non-small cell lung cancer' then nsclc and squamous
	when 'non-squamous non-small cell lung cancer' then nsclc and non_squamous
    end as match
from histology h
join ct.lca_histology_category m using (histology)
cross join attribute
where attribute_group='histology'
;

/***
 * drug therapies
 */
set search_path=ct_lca;

drop table if exists patient_attribute_chemotherapy;
create table patient_attribute_chemotherapy as
select person_id, lot_drugs as patient_value
, attribute_id, attribute_group, attribute_name, value
, case nvl(attribute_name, '') || ', ' || value 
	when ', yes' then chemo
	when ', platinum-based' then platin
	when ', cisplatin-based' then lot_drugs ilike '%cisplatin%'
	when ', carboplatin-based' then lot_drugs ilike '%carboplatin%'
    end as match
from p_lot_drugs
cross join attribute
where attribute_group='chemotherapy'
;
select * from patient_attribute_chemotherapy;

drop table if exists patient_attribute_immunotherapy;
create table patient_attribute_immunotherapy as
select person_id, lot_drugs as patient_value
, attribute_id, attribute_group, attribute_name, value
, case nvl(attribute_name, '') || ', ' || value 
	when ', yes' then immuno
	when 'all PD-1 abs, yes' then pd_1
	when 'PD-1 ab, Pembrolizumab' then patient_value ilike '%pembrolizumab%'
	when 'PD-1 ab, Nivolumab' then patient_value ilike '%nivolumab%'
	when 'all PD-L1/L2 abs, yes' then pd_l
	when 'PD-L1/L2 ab, Atezolizumab' then patient_value ilike '%atezolizumab%'
	when 'PD-L1/L2 ab, Avelumab' then patient_value ilike '%avelumab%'
	when 'PD-L1/L2 ab, Durmalumab' then patient_value ilike '%durmalumab%'
	when 'all CTLA-4 abs, yes' then ctla_4
	when 'CTLA-4 ab, Ipilimumab' then patient_value ilike '%ipilimumab%'
    end as match
from p_lot_drugs
cross join attribute
where attribute_group='immuotherapy' -- typo
;
select * from patient_attribute_immunotherapy;

drop table if exists patient_attribute_targetedtherapy;
create table patient_attribute_targetedtherapy as
select person_id, lot_drugs as patient_value
, attribute_id, attribute_group, attribute_name, value
, case nvl(attribute_name, '') || ', ' || value 
	when ', yes' then targeted
	when 'all EGFR inhibitors, yes' then egfr
	when 'EGFR inhibitor, Afatinib' then patient_value ilike '%afatinib%'
	when 'EGFR inhibitor, Gefitinib' then patient_value ilike '%gefitinib%'
	when 'EGFR inhibitor, Erlotinib' then patient_value ilike '%erlotinib%'
	when 'EGFR inhibitor, Osimertinib' then patient_value ilike '%osimertinib%'
	when 'EGFR inhibitor, Cetuximab' then patient_value ilike '%cetuximab%'
	when 'ALK inhibitor, yes' then alk
	when 'ALK inhibitor, Crizotinib' then patient_value ilike '%crizotinib%'
	when 'RET inhibitor, yes' then false -- no drug found in lca
	when 'RET inhibitor, Carbozantinib' then patient_value ilike '%carbozantinib%'
	when 'PARP inhibitor, yes' then false -- no drug found in lca
	when 'PARP inhibitor, Olaparib' then patient_value ilike '%Olaparib%'
	when 'c-MET inhibitor, yes' then false -- no met drug found in lca
    end as match
from p_lot_drugs
cross join attribute
where lower(attribute_group)='targeted therapy' -- typo
;
select * from patient_attribute_targetedtherapy
order by person_id, attribute_id;
select * from p_lot_drugs;
/***
 * patient_attibute combined
 */ 
create or replace view ct_lca.patient_attribute as
	select person_id, attribute_id, match, patient_value::varchar from patient_attribute_age
	union select person_id, attribute_id, match, patient_value::varchar from patient_attribute_ecog
    union select person_id, attribute_id, match, patient_value::varchar from patient_attribute_stage
    union select person_id, attribute_id, match, patient_value::varchar from patient_attribute_histology
	union select person_id, attribute_id, match, patient_value::varchar from patient_attribute_lot
	union select person_id, attribute_id, match, patient_value::varchar from patient_attribute_chemotherapy
	union select person_id, attribute_id, match, patient_value::varchar from patient_attribute_immunotherapy
	union select person_id, attribute_id, match, patient_value::varchar from patient_attribute_targetedtherapy
	union select person_id, attribute_id, match, patient_value::varchar from patient_attribute_lab
	union select person_id, attribute_id, match, patient_value::varchar from patient_attribute_mutation_egfr
	union select person_id, attribute_id, match, patient_value::varchar from patient_attribute_mutation_alk
	union select person_id, attribute_id, match, patient_value::varchar from patient_attribute_mutation_ros
	union select person_id, attribute_id, match, patient_value::varchar from patient_attribute_mutation_kras
	union select person_id, attribute_id, match, patient_value::varchar from patient_attribute_mutation_braf
	union select person_id, attribute_id, match, patient_value::varchar from patient_attribute_mutation_her2
order by person_id, attribute_id;
select * from patient_attribute;

/***
 * master_sheet trial checks + patient checks
 */
create or replace view master_sheet as
select trial_id, person_id, attribute_id
, a.attribute_group, a.attribute_name, a.value
, t.inclusion, t.exclusion, p.match patient_match, patient_value
from attribute a
join trial_attribute t using (attribute_id)
join patient_attribute p using (attribute_id)
order by trial_id, person_id, attribute_id
;
select * from master_sheet;

-- make into table for performance
create table master_sheet_nsclc_20191102 as
select m.* from master_sheet m 
join ct_nsclc.demo using (person_id)
;
show search_path;
-- view master_sheet for order filtering and masking
create or replace view v_master_sheet_nsclc_20191102 as
select trial_id, person_id+3040 as person_id, attribute_id,
attribute_group, attribute_name, value, inclusion, exclusion, patient_match, patient_value
from master_sheet_nsclc_20191102
order by trial_id, person_id, attribute_id
;

select * from v_master_sheet_nsclc_20191101;
-- view patient_attr for order filtering and masking
create or replace view v_patient_attribute as
select person_id+3040 as person_id, attribute_id, match patient_match, patient_value
from patient_attribute
join ct_nsclc.demo using (person_id)
order by person_id, attribute_id
;
select * from  v_patient_attribute_nsclc_20191101;

select * from trial_attribute
order by trial_id, attribute_id
;




--17
select count(distinct trial_id) from master_sheet_nsclc_20191101;
-- 2942
select count (distinct person_id) from master_sheet_nsclc_20191101;
select * from master_sheet_nsclc

where person_id in (
	select distinct person_id from master_sheet_nsclc order by person_id limit 10)
order by trial_id, person_id, attribute_id;

set search_path=ct_lca;
select * from trial_attribute join attribute using (attribute_id);
select * from trial_attribute order by trial_id, attribute_id;
select pa.* from patient_attribute pa join ct_nsclc.demo using (person_id) order by person_id, attribute_id;

/***
 * master_pivot
 */
set search_path=ct_lca;
create view masterpivot_nsclc as
select *
from ct_nsclc.demo
left join histology using (person_id)
left join stage using (person_id)
left join lot using (person_id)
left join last_lab_pivot using (person_id)
left join _variant_listedgene_pivot using (person_id)
order by person_id;




-- filtering for patients
select distinct person_id from ct_lca.master_sheet_nsclc where trial_id='NCT03976323' 
and attribute_group='stage' and inclusion='yes' and patient_match
intersect
select distinct person_id from ct_lca.master_sheet_nsclc where trial_id='NCT03976323' 
and attribute_group='line of therapy' and inclusion='yes' and patient_match;

