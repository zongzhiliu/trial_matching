-- settings
@set disease=CD
@set disease_icd=^(K50|555[.][0-1])
@set last_visit_within=99
@set ref_drug_mapping=ct.drug_mapping_cat_expn5_20200317
@set ref_lab_mapping=ct.ref_lab_loinc_mapping
set search_path=ct_${disease};

drop view if exists ref_drug_mapping;
drop view if exists ref_lab_mapping;

create view ref_drug_mapping as
select * from ${ref_drug_mapping}
;
create view ref_lab_mapping as
select * from ${ref_lab_mapping}
;

