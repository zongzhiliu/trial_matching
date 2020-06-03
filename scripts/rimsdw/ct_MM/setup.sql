/***
To be deprecated!
Dependencies
Results:
    trial_attribute_raw
    crit_attribute_raw
    ref_drug_mapping
    ref_lab_mapping
*/
create or replace view trial_attribute_raw as
select * from ${trial_attribute};

create or replace view crit_attribute_raw as
select * from ${crit_attribute};

create or replace view crit_attribute_mapping_raw as
select * from ${crit_attribute_mapping};

create or replace view ref_drug_mapping as
select * from ${ref_drug_mapping};

create or replace view ref_lab_mapping as
select * from ${ref_lab_mapping};

/*
create or replace view ref_histology_mapping as
select * from ct.pca_histology_category;

*/

