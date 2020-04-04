/***
To be deprecated!
Dependencies
Results:
    _trial_attribute_raw
    _crit_attribute_raw
    ref_drug_mapping
    ref_lab_mapping
    ref_histology_mapping
settings:
    @set cancer_type=MM
    @set cancer_type_icd=^(C90|230)
*/
--create schema if not exits ct_${cancer_type};
--set search_path=ct_${cancer_type};
--show search_path;
-- settings
/*
create or replace view _crit_attribute_raw as
select * from crit_attribute_raw_20200306;

create or replace view _trial_attribute_raw as
select * from trial_attribute_raw_20200305;
*/

create or replace view ref_drug_mapping as
select * from ct.drug_mapping_cat_expn3_20200308;

create or replace view ref_lab_mapping as
select * from ct.ref_lab_loinc_mapping;
/*
create or replace view ref_histology_mapping as
select * from ct.pca_histology_category;
*/

