/***
* excise on a specific trial: prostate
*/
create schema ct_NCT03748641;
set search_path=ct_NCT03748641;

-- attribute_used
create table attribute_used as
select distinct attribute_id, attribute_group, attribute_name, attribute_value
, inclusion, exclusion, mandatory, logic
from ct_pca.trial_attribute_used tau
join ct_pca.crit_attribute_used cau using (attribute_id)
join ct_pca._master_match using (trial_id, attribute_id)
where trial_id='NCT03748641'
    and match is not null
    and nvl(inclusion, exclusion) is not null
order by attribute_id;

select au.*
, patients
from attribute_used au
join ct_pca._leaf_summary using (attribute_id)
where trial_id='NCT03748641'
order by attribute_id
;

select sum(match::int)
from _p_a_match
where attribute_id=411
;

/* Explore
select distinct loinc_code, ll.loinc_display_name, ll.unit, source_test_name, ll.source_unit 
from prod_msdw.all_labs
join latest_lab ll using (loinc_code)
where source_test_name ilike '%testo%';
;
*/
-- create table inc_count as
create table inc_patient as
with met as (
	select distinct person_id
	from ct_pca._all_dx
	where icd_code ~ '^(C7[789B]|19[678])'
), testo as (
	select distinct person_id
	from ct_pca.latest_lab
	where loinc_code='49041-7'
		and value_float<=50
)
select * from met intersect
select * from testo
;
/*
select 'met' crit, count(*) patients from met union all
select 'testo', count(*) from testo
*/

-- bone met
create table _bone_met as
with bonemet as (
	select distinct person_id
	from ct_pca._all_dx
	where icd_code ~ '^(C79[.]5|198[.]5)'
), stage as (
	select distinct person_id 
	from ct_pca.stage
	where stage_base='IV'
)
select 'bonemet', count(*) from bonemet union all
select 'stage_iv', count(*) from stage
;

--select count(distinct person_id) from _all_dx;

--create table exc_count as
create table exc_patient as
with parp as (
    select distinct person_id
    from ct_pca._drug
    where moa ilike '%parp_targeted%'
), taxane as (
    select distinct person_id
    from ct_pca._drug
    where moa like '%Taxanes%'
), antiandr2 as (
    select distinct person_id
    from ct_pca._drug
    where moa like '%Second_gen_anti_androgen%'
), aml as (
    select distinct person_id
    from ct_pca._all_dx
    where icd_code ~ '^(C92[.]0|205[.]0)'
), mds as (
    select distinct person_id
    from ct_pca._all_dx
    where icd_code ~ '^(D46|238[.]7[2-5])'
)
/*select 'parp', count(*) from parp union all
select 'taxane', count(*) from taxane union all
select 'antiandr2', count(*) from antiandr2 union all
select 'aml', count(*) from aml union all
select 'mds', count(*) from mds
*/
select * from parp union
select * from taxane union
select * from antiandr2 union
select * from aml union
select * from mds
;

create table eligible_patient as
select * from inc_patient except
select * from exc_patient
;

drop table if exists eligible_count;
create table eligible_count as
select 'all_inc', count(*) from inc_patient union all
select 'all_exc', count(*) from exc_patient union all
select 'eligible', count(*) from eligible_patient
;
/*
select *
from ct.drug_mapping_cat_expn6
where drug_name='darolutamide' --missing
where moa ilike '%second%' --Second_gen_anti_androgen
where moa ilike '%taxan%' --Taxanes
*/
;
select * from inc_count;
select * from exc_count;
select * from eligible_count;
