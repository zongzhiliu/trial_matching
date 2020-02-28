/***
Dependencies
Results:
    trial_attribute_used
    crit_attribute_used
    ref_drug_mapping
    ref_lab_mapping
    ref_histology_mapping
settings:
    @set cancer_type=PCA
    @set cancer_type_icd=^(C61|185)
*/
set search_path=ct_${cancer_type};
show search_path;
-- settings
create or replace view _crit_attribute_raw as
select * from ct.crit_attribute_raw_20200223;

create or replace view _trial_attribute_raw as
select * from trial_attribute_raw_20200223;

create or replace view ref_drug_mapping as
select * from ct.drug_mapping_cat_expn3;

create or replace view ref_lab_mapping as
select * from ct.ref_lab_loinc_mapping;

create or replace view ref_histology_mapping as
select * from ct.pca_histology_category;


/***
* trial, crit, attributes
*/
-- trial_attribute_used
drop table if exists trial_attribute_used;
create table trial_attribute_used as
select * from _trial_attribute_raw
where nvl(inclusion, exclusion) is not null
;
-- crit_attribute_used
drop table if exists crit_attribute_used cascade;
create table crit_attribute_used as
select crit_id, crit_name, mandated
, attribute_id, c.attribute_group, c.attribute_name, c.value
from _crit_attribute_raw c
join (select distinct attribute_id
    from trial_attribute_used) using (attribute_id)
;
create or replace view v_crit_attribute_used as
select attribute_id, attribute_group, attribute_name, value, mandated, crit_id
from crit_attribute_used
order by attribute_id
;
/*qc
select count(*) from crit_attribute_used;
    --170
*/
