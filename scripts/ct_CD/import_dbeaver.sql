-- settings
@set disease=CD
@set disease_icd=^(K50|555[.][0-1])
--@set last_visit_within=99
@set dmsdw=dmsdw_2019q1
@set ref_drug_mapping=ct.drug_mapping_cat_expn6
@set ref_lab_mapping=ct.ref_lab_loinc_mapping
@set ref_proc_mapping=ct.ref_proc_mapping_20200325
@set ref_rx_mapping=ct.ref_rx_mapping_20200325
set search_path=ct_${disease};

--@source path/to/_.sql
-- cohort
-- vital
-- sochx
-- dx
-- rx
-- lab
-- prog
-- surg

