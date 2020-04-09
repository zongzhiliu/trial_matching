/***
Dependencies
Results:
    trial_attribute_used
    crit_attribute_used
    ref_drug_mapping
    ref_lab_mapping
    ref_histology_mapping
load_into_db_schema_some_csvs.py rimsdw ct crit_attribute_used_lca_pca_20200408.csv -d
*/
create or replace view _crit_attribute_raw as
--select * from ct.crit_attribute_raw_20200223;
select * from ct.crit_attribute_used_lca_pca_20200408;

create or replace view _trial_attribute_raw as
select * from trial_attribute_raw_20200223;

create or replace view ref_drug_mapping as
select * from ${ref_drug_mapping}; --ct.drug_mapping_cat_expn3;

create or replace view ref_lab_mapping as
select * from ${ref_lab_mapping}; --ct.ref_lab_loinc_mapping;

create or replace view ref_histology_mapping as
select * from ct.pca_histology_category;


/***
* trial, crit, attributes
*/
-- trial_attribute_used
drop table if exists trial_attribute_used;
create table trial_attribute_used as
select *
, inclusion is not null as ie_flag
, nvl(inclusion, exclusion) ie_value
from _trial_attribute_raw
where ie_value is not null
    and ie_value !~ 'yes <[24]W' --quickfix
;
/*
with tmp as (
    select attribute_id
    , listagg(distinct nvl(inclusion, exclusion), '| ') ie_values
    from trial_attribute_used
    group by attribute_id
)
select attribute_id, ie_values, a.*
from tmp join crit_attribute_raw a using (attribute_id)
order by attribute_id
;
*/
-- crit_attribute_used
--alter table crit_attribute_used rename to crit_attribute_used_old_20200408;
drop table if exists crit_attribute_used cascade;
create table crit_attribute_used as
select attribute_id, attribute_group, attribute_name, attribute_value
, mandatory_default, logic_default
from _crit_attribute_raw c
join (select distinct attribute_id
    from trial_attribute_used) using (attribute_id)
;

--drop view v_crit_attribute_used;
create or replace view v_crit_attribute_used as
select attribute_id, attribute_group, attribute_name, attribute_value
, mandatory_default, logic_default
from crit_attribute_used
order by attribute_id
;
/*qc
select count(*) from crit_attribute_used;
    --170
    --183
*/
