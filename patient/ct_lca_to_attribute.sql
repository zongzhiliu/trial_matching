set search_path=ct_lca;
/***
 * patient_attribute_stage
 */

--drop table if exists ct_lca.patient_attribute_stage;
create table ct_lca._p_a_stage as
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
	 when 'limited stage' then stage_base between 'I' and 'III'
	 when 'extensive stage' then stage_base = 'IV'
	end as match
from ct_lca.stage
cross join ct_lca.attribute
where attribute_group='stage' and attribute_name='stage'
;

--select * from ct_lca._p_a_stage;


/***
* mutations
*/
-- make patient atrribute match
--drop table if exists ct_lca.patient_attribute_mutation;
create table ct_lca._p_a_mutation as
select person_id
, case attribute_name
	when 'EGFR' then egfr
	when 'KRAS' then kras
	when 'BRAF' then braf
	when 'HER2' then erbb2
	when 'Alk fusion' then lower(alk)
	when 'ROS1 fusion' then lower(ros)
	end as patient_value
, attribute_id, attribute_group, attribute_name, value
, case attribute_name || ', ' || value 
	when 'EGFR, yes' then patient_value is not NULL
	when 'EGFR, exon19 deletion' then patient_value ~ 'Exon 19 Deletion'
	when 'EGFR, L858R' then patient_value ~ 'p.L858R'
	when 'EGFR, T790M' then patient_value ~ 'p.T790M'
	when 'KRAS, yes' then patient_value is not NULL
	when 'KRAS, G12' then patient_value ~ 'p.G12\\D|Codon 12 '
	when 'BRAF, yes' then patient_value is not NULL
	when 'BRAF, V600' then patient_value ~ 'p.V600\\D'	
	when 'HER2, yes' then patient_value is not NULL
	when 'ALK fusion, yes' then patient_value ~ 'fusion'
	when 'ROS1 fusion, yes' then patient_value ~ 'fusion'
	end as match
from ct_lca._variant_listedgene_pivot
cross join ct_lca.attribute
where attribute_group='mutation'
;
--select * from _p_a_mutation order by person_id, attribute_id;

/***
 * line_of_therapy
 */
--set search_path=ct_lca;
create table _p_a_lot as
select person_id, n_lot as patient_value
, attribute_id, attribute_group, attribute_name, value
, case value when '0' then n_lot=0
    when '1' then n_lot=1
    when '2' then n_lot=2
    when '3' then n_lot=3
    when '>=4' then n_lot>=4  -- to be fixed in attribute excel
    end as match
from lot
cross join attribute
where attribute_group='line of therapy' and attribute_name is null
;
/*-- check
select * from _p_a_lot;
select *
from (select *, row_number() over (partition by n_lot
        order by person_id)
    from lot_checks)
where row_number=1
order by n_lot
;
*/


/***
* age from wen's age_of_now
*/
--select distinct age_of_now from ct_nsclc.patient_demo;
--set search_path=ct_lca;
drop table if exists _p_a_age;
create table _p_a_age as
select person_id, age_of_now as patient_value
, attribute_id, attribute_group, attribute_name, value
, case value 
    when '>=12' then patient_value >=12
    when '>=18' then patient_value >=18
    when '>=20' then patient_value >=20
    when '<=75' then patient_value <=75
    end as match
from ct_nsclc.patient_demo
cross join attribute
where attribute_group='age' --attribute_name does not matter here
;
select * from _p_a_age;

/*** 
* ecog from wen's ecog_final
*/
--select distinct ecog_latest from ct_nsclc.demo_lca_ecog_final;
--set search_path=ct_lca;
create table _p_a_ecog as
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
where attribute_group='ecog' and attribute_name='ecog'
;
--select * from _p_a_ecog;
--show search_path;


/***
 * histology mapped
 */
--set search_path=ct_lca;
--select * from histology join ct.lca_histology_category using (histology);
create table _p_a_histology as
select person_id, h.histology as patient_value
, attribute_id, attribute_group, attribute_name, value
, case attribute_name || '; ' || value 
	when 'non-small cell lung cancer; yes' then nsclc
	when 'non-small cell lung cancer; squamous non-small cell lung cancer' then nsclc and squamous
	when 'non-small cell lung cancer; non-squamous non-small cell lung cancer' then nsclc and non_squamous
	when 'small cell lung cancer; yes' then sclc
    end as match
from histology h
join ct.lca_histology_category m using (histology)
cross join attribute
where attribute_group='histology'
;
--select * from _p_a_histology;

/***
 * drug therapies
 */
--set search_path=ct_lca;
--drop table if exists patient_attribute_chemotherapy;
create table _p_a_chemotherapy as
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
select * from _p_a_chemotherapy;

--drop table if exists patient_attribute_immunotherapy;
create table _p_a_immunotherapy as
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
--select * from _p_a_immunotherapy;

--drop table if exists _p_a_targetedtherapy;
create table _p_a_targetedtherapy as
select person_id, lot_drugs as patient_value
, attribute_id, attribute_group, attribute_name, value
, case nvl(attribute_name, '') || ', ' || value 
	when ', yes' then targeted
	when 'EGFR inhibitor, yes' then egfr
	when 'EGFR inhibitor, Afatinib' then patient_value ilike '%afatinib%'
	when 'EGFR inhibitor, Gefitinib' then patient_value ilike '%gefitinib%'
	when 'EGFR inhibitor, Erlotinib' then patient_value ilike '%erlotinib%'
	when 'EGFR inhibitor, Osimertinib' then patient_value ilike '%osimertinib%'
	when 'EGFR inhibitor, Cetuximab' then patient_value ilike '%cetuximab%'
	when 'ALK inhibitor, yes' then alk
	when 'ALK inhibitor, Crizotinib' then patient_value ilike '%crizotinib%'
	when 'ALK inhibitor, Alectinib' then patient_value ilike '%alectinib%'
	when 'ALK inhibitor, Ceritinib' then patient_value ilike '%ceritinib%'
	when 'RET inhibitor, yes' then patient_value ilike '%carbozantinib%' -- no ret_targeted defined yet
	when 'RET inhibitor, Carbozantinib' then patient_value ilike '%carbozantinib%'
	when 'PARP inhibitor, yes' then patient_value ilike '%olaparib%' -- no drug found in lca
	when 'PARP inhibitor, Olaparib' then patient_value ilike '%olaparib%'
	when 'c-MET inhibitor, yes' then patient_value ilike '%carbozantinib%' -- no met drug found in lca
	when 'ROS1 inhibitor, yes' then ros
	when 'BRAF inhibitor, yes' then patient_value ilike '%vemurafenib%' -- no category yet
	when 'BRAF inhibitor, vemurafenib' then patient_value ilike '%vemurafenib%'
	when 'RAF inhibitor, yes' then patient_value ilike '%sorafenib%'
	when 'RAF inhibitor, sorafenib' then patient_value ilike '%sorafenib%'
	when 'MEK inhibitor, yes' then NULL -- to be implemented later as a category
	when 'MEK inhibitor, cobimetinib' then patient_value ilike '%cobimetinib%'
    end as match
from p_lot_drugs
cross join attribute
where lower(attribute_group)='targeted therapy' -- typo
;
--select * from _p_a_targetedtherapy order by person_id, attribute_id;

/***
 * diseases
 */
-- CNS disease
drop table if exists _p_a_cns_disease;
create table _p_a_cns_disease as
select person_id, NULL as patient_value
, attribute_id, attribute_group, attribute_name, value
, case attribute_name || '; ' || value
	when 'Brain met; yes' then 
		bool_or(icd_code ~ '^(C79\\.31|198\\.3)')
	when 'Leptomeningeal; yes' then
		bool_or(icd_code ~ '^(G93|348)')
	when 'Carcinomatous meningitis; yes' then 
		bool_or(icd_code ~ '^(C70\\.9|192\\.1)')
	when 'Spinal cord compression; yes' then
		bool_or(icd_code ~ '^(G95\\.20|336\\.9)')
	end as match 
from attribute
cross join latest_icd
where attribute_group='CNS Disease'
group by attribute_id, person_id, attribute_group, attribute_name, value
order by person_id, attribute_id
;
-- other disease
create table _p_a_other_disease as
select person_id, NULL as patient_value
, attribute_id, attribute_group, attribute_name, value
, case attribute_name || '; ' || value
	when 'Other malignancy; yes' then 
		bool_or(icd_code ~ '^(C|1[4-9]|20)' and icd_code !~ '^(C34|162)') -- all malignancies but lung
	when 'Immunodeficiency/HIV infection; yes' then
		bool_or(icd_code ~ '^(D84\\.9|279\\.3)')
	when 'Cardiovascular disease; yes' then 
		bool_or(icd_code ~ '^(I50)')
	when 'Interstitial lung disease; yes' then
		bool_or(icd_code ~ '^(J84)')
	end as match 
from attribute
cross join latest_icd
where attribute_group='Disease'
group by attribute_id, person_id, attribute_group, attribute_name, value
order by person_id, attribute_id
;

/***
 * lab from wen's nsclc.person_lab_attribute_mapping
 * lav_value vs unit converted to criteria as patient_value
 */
--select * from ct_lca.person_lab_attribute_mapping;
drop table if exists _p_a_lab;
create table _p_a_lab as
select person_id, lab_value || ' vs ' || value_to_compare as patient_value
, attribute_id, attribute_group, attribute_name, value_rule as value
, meet_attribute_rule as match
from ct_lca.person_lab_attribute_mapping
--join attribute_old_20191107 using (attribute_id)
join attribute using (attribute_id)
;
--set search
select distinct attribute_id,attribute_name, value from ct_lca._p_a_lab;

/***
 * patient_attibute combined
 */ 
create or replace view v_p_a_combined as
with p_a_combined as (
	select person_id, attribute_id, match, patient_value::varchar from _p_a_age
	union select person_id, attribute_id, match, patient_value::varchar from _p_a_ecog
    union select person_id, attribute_id, match, patient_value::varchar from _p_a_stage
    union select person_id, attribute_id, match, patient_value::varchar from _p_a_histology
	union select person_id, attribute_id, match, patient_value::varchar from _p_a_lot
	union select person_id, attribute_id, match, patient_value::varchar from _p_a_chemotherapy
	union select person_id, attribute_id, match, patient_value::varchar from _p_a_immunotherapy
	union select person_id, attribute_id, match, patient_value::varchar from _p_a_targetedtherapy
	union select person_id, attribute_id, match, patient_value::varchar from _p_a_lab
	union select person_id, attribute_id, match, patient_value::varchar from _p_a_cns_disease
	union select person_id, attribute_id, match, patient_value::varchar from _p_a_other_disease
)
select person_id, attribute_id, match attribute_match, patient_value
from p_a_combined
order by person_id, attribute_id
;

--select * from v_p_a_combined;





