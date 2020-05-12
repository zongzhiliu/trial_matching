/***
Dependencies: ref tables
, trial_attribute_raw
, crit_attribute_raw: attribute_id, attribute_g/n/v
, crit_attribute_mapping: attribute_id, new_attribute_g/n/v, logic_default, mandatory_default
Results:
    trial_attribute_used
    crit_attribute_used
    _crit_attribute_mapped
*/
/*
create or replace view ref_drug_mapping as
select * from ${ref_drug_mapping}
; --ct.drug_mapping_cat_expn3;
*/

drop view if exists ref_histology_mapping;
create view ref_histology_mapping as
--select * from ${ref_histology_mapping}
select * from ct.lca_histology_category
;

create view cohort as select * from ct_nsclc.cohort;
create view demo_plus as select * from ct_nsclc.demo_plus;
create view stage as select * from ct_nsclc.stage;
create view biomarker as select * from ct_nsclc.biomarker;
create view latest_icd as select * from ct_nsclc.latest_icd;
create view latest_lab as select * from ct_nsclc.latest_lab;
create view histology as select * from ct_nsclc.histology;
create view latest_lot_drug as select * from ct_nsclc.latest_lot_drug;
create view _variant_significant as select * from ct_nsclc._variant_significant;
create view latest_ecog as select * from ct_nsclc.latest_ecog;
create view latest_karnofsky as select * from ct_nsclc.latest_karnofsky;
create view lot as select * from ct_nsclc.lot;


drop view if exists _crit_attribute_raw cascade;
create view _crit_attribute_raw as
select attribute_id
, attribute_group
, nvl(attribute_name, '_') attribute_name
, nvl(attribute_value, '_') attribute_value
, code_type
, nvl(code_base, '_') code_raw
, code_ext
, code_transform
, case when code_type like 'icd%' then
        replace('^('+code_raw+'|'+nvl(code_ext, '__')+')', '.', '[.]') -- quickfix code_ext null
    when code_type like 'gene%' then
        '^('+code_raw+')$'
    when code_type in ('drug_name') then
        lower(code_raw)
    else code_raw
    end code
--from ${crit_attribute}
from ct.pd_attribute_20200511
;

select ct.assert(count(*) = count(distinct attribute_id)
, 'attribute_id should be unique') from _crit_attribute_raw
;
select ct.assert(bool_and(attribute_group+attribute_name+attribute_value is not null)
, 'each attribute should have nonempty group, name, value') from _crit_attribute_raw
;


-- crit_attribute_used
drop table if exists crit_attribute_used cascade;
create table crit_attribute_used as
select attribute_id, attribute_group, attribute_name, attribute_value
, code_type, code, code_ext, code_transform
from _crit_attribute_raw c
;
select count(*) from crit_attribute_used;
