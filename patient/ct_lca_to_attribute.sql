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
 * patient_attibute combined
 */ 
create table ct_lca.patient_attribute as
	select person_id, attribute_id, patient_value::varchar, match from patient_attribute_lot
	union select person_id, attribute_id, patient_value::varchar, match from patient_attribute_stage
	union select person_id, attribute_id, patient_value::varchar, match from patient_attribute_mutation_egfr
	union select person_id, attribute_id, patient_value::varchar, match from patient_attribute_mutation_alk
	union select person_id, attribute_id, patient_value::varchar, match from patient_attribute_mutation_ros
	union select person_id, attribute_id, patient_value::varchar, match from patient_attribute_mutation_kras
	union select person_id, attribute_id, patient_value::varchar, match from patient_attribute_mutation_braf
	union select person_id, attribute_id, patient_value::varchar, match from patient_attribute_mutation_her2
;

/***
 * line_of_therapy
 */

/***
 * trial checks + patient checks
 */
create table master_sheet as
select trial_id, person_id, attribute_id
, a.attribute_group, a.attribute_name, a.value
, t.inclusion, t.exclusion, patient_value, p.match patient_match
from attribute a
join trial_attribute t using (attribute_id)
join patient_attribute p using (attribute_id)
order by trial_id, person_id, attribute_id
;

create view master_sheet_nsclc as
select m.* from master_sheet m join ct_nsclc.demo using (person_id) order by trial_id, person_id, attribute_id;
select count (distinct person_id) from master_sheet_nsclc;
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

/***
* age from wen's age_of_now
*/
select distinct age_of_now from ct_nsclc.patient_demo;