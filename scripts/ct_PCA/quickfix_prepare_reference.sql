-- load_into_db_schema_some_csvs.py rimsdw ct crit_attribute_used_lca_pca_20200410.csv -d
drop view if exists _crit_attribute_raw;
create view _crit_attribute_raw as
--select * from ct.crit_attribute_raw_20200223;
select attribute_id
, attribute_group, attribute_name, value attribute_value
from ct.crit_attribute_used_lca_pca_20200410;

select count(*), count(distinct attribute_id) from _crit_attribute_raw;

drop view if exists _crit_attribute_raw_updated;
create view _crit_attribute_raw_updated as
select attribute_id
, new_attribute_group attribute_group
, new_attribute_name attribute_name
, new_attribute_value attribute_value
, logic_default
, mandatory_default
from ct.crit_attribute_used_lca_pca_20200410;

create or replace view _trial_attribute_raw as
select * from trial_attribute_raw_20200223;

create or replace view ref_drug_mapping as
select * from ${ref_drug_mapping}; --ct.drug_mapping_cat_expn3;

create or replace view ref_lab_mapping as
select * from ${ref_lab_mapping}; --ct.ref_lab_loinc_mapping;

create or replace view ref_histology_mapping as
select * from ct.pca_histology_category;
