-- settings
@set disease=CD
@set disease_icd=^(K50|555[.][0-1])
@set last_visit_within=99
@set ref_drug_mapping=ct.drug_mapping_cat_expn5_20200317
@set ref_lab_mapping=ct.ref_lab_loinc_mapping
set search_path=ct_${disease};
show search_path;

-- cohort
-- vital
-- sochx
-- dx
-- rx
-- lab
-- prog
-- surg

/*********
 * explore
 */
select * from _kinds_of_procedures
where lower(procedure_description) ~
--'transfusion'
'stem cell'
--'pluripotent'
;

create table _kinds_of_rx_ as
select rx_name, rx_generic, context_material_code, context_name, count(*) records
from _rx
group by rx_name, rx_generic, context_material_code, context_name
; -- code is not helpfule
select * from _kinds_of_rx_ order by rx_name, rx_generic, context_name, context_material_code;

create table _kinds_of_rx as
select rx_name, rx_generic, count(*) records
from rx
group by rx_name, rx_generic
;
select * from _kinds_of_rx
where lower(rx_name || '; ' || rx_generic) ~
'hydroxy'
;
select * from dx
where lower(description) ~ 'alcohol abuse'
;

drop table _kinds_of_icds;
create table _kinds_of_icds as
select context_name, context_diagnosis_code, description
, count(*) records
from dx
where description != 'NOT AVAILABLE'
group by context_name, context_diagnosis_code, description
;
grant all on schema ct_scd to wen_pan;
select * from dmsdw_2019q1.d_person limit 10;


