set search_path=ct_lca;

/***
 * demo
 */
create table demo as
select distinct person_id, date_of_birth, gender_name, date_of_death, race_name, ethnicity_name
from cplus_from_aplus.cancer_diagnoses cd
--join cplus_from_aplus.cancer_types using (cancer_type_id)
join cplus_from_aplus.people p using (person_id)
join cplus_from_aplus.genders g using (gender_id)
join cplus_from_aplus.races r using (race_id)
join cplus_from_aplus.ethnicities using (ethnicity_id)
where cd.status != 'deleted' and p.status != 'deleted'
	and cancer_type_id=1 --and cancer_type_name='LCA'
;
-- 5007
select count(*) from demo;

create table _all_labs as
select l.*
from demo
join prod_msdw.all_labs l using (person_id)
;

create table _all_loinc as
select distinct loinc_code, loinc_display_name, unit
from _all_labs
;

-- 163
select * from _all_loinc;

create table _labs as
select distinct person_id, result_date::date, loinc_code, loinc_display_name, value_float, value_range_low, value_range_high, unit
, source_value, source_unit
from _all_labs a
join ct.reference_lab using (loinc_code)
where value_float is not null
;

drop table last_lab;
create table last_lab as
select person_id, result_date as last_date, loinc_code, loinc_display_name, value_float, unit
from (select *, row_number() over (
		partition by person_id, loinc_code
		order by result_date desc nulls last, value_float desc nulls last)
		from _labs)
where row_number=1
order by person_id, last_date, loinc_code
;
--select * from last_lab order by person_id limit 10;


create table last_lab_pivot as
select person_id
, max(case when loinc_code='1920-8' then value_float end) lab_ast
, max(case when loinc_code='1742-6' then value_float end) lab_alt
, max(case when loinc_code='1975-2' then value_float end) lab_total_bilirubin
, max(case when loinc_code='1968-7' then value_float end) lab_direct_bilirubin
, max(case when loinc_code='2160-0' then value_float end) lab_serum_creatinine
, max(case when loinc_code='2164-2' then value_float end) lab_crcl
, max(case when loinc_code='48462-3' then value_float end) lab_egfr
, max(case when loinc_code='777-3' then value_float end) lab_platelets
, max(case when loinc_code='26499-4' then value_float end) lab_anc
, max(case when loinc_code='718-7' then value_float end) lab_hemoglobin
, max(case when loinc_code='26464-8' then value_float end) lab_wbc
--, max(case when loinc_code='1558-6' then value_float end) lab_fpg
from last_lab
GROUP BY person_id
--order by person_id
--limit 100
;

/***
* histology
*/
create table histology as
select person_id
, histologic_icdo, histologic_type_name as histology
from demo
left join cplus_from_aplus.cancer_diagnoses cd using (person_id)
join prod_references.histologic_types h using (histologic_type_id, cancer_type_id)
where cd.status != 'deleted'
    and cancer_type_id=1
--limit 10
;

drop table if exists histology_checks;
create table histology_checks as
select person_id, histologic_icdo, histology
, histologic_icdo ~ '804[1-5]/3' as SCLC
, histologic_icdo !~ '804[1-5]/3' as NSCLC
, NSCLC and histology in ('Squamous Cell Carcinoma') squamous
, NSCLC and histology not in ('Squamous Cell Carcinoma') as non_squamous
from histology
--limit 10
;
select * from histology_checks limit 10;
select *
from (select *, row_number() over (partition by histology
        order by person_id)
    from histology_checks)
where row_number=1
order by histology
;

/***
* stage
*/
create temporary table _stage as
select person_id, overall_stage stage
, regexp_substr(stage, '^[0IV]+') stage_base
, regexp_substr(stage, '[A-C].*') stage_ext
, regexp_substr(stage, '^[0IV]+[A-C].*') stage_full
from demo
left join cplus_from_aplus.cancer_diagnoses cd using (person_id)
where cd.status != 'deleted'
;
create table stage as
select person_id, stage
, case when stage_base='' then NULL else stage_base end stage_base
, case when stage_ext='' then NULL else stage_ext end stage_ext
, case when stage_full='' then NULL else stage_full end stage_full
from _stage
;
drop table if exists stage_checks;
create table stage_checks as
select person_id, stage --, stage_unknown
, stage_base='I' as stage_I
, stage_base='I' and stage_ext like 'A%' as stage_IA
, stage_base='I' and stage_ext like 'B%' as stage_IB
, stage_base='II' as stage_II
, stage_base='II' and stage_ext like 'A%' as stage_IIA
, stage_base='II' and stage_ext like 'B%' as stage_IIB
, stage_base='III' as stage_III
, stage_base='III' and stage_ext like 'A%' as stage_IIIA
, stage_base='III' and stage_ext like 'B%' as stage_IIIB
, stage_base='III' and stage_ext like 'C%' as stage_IIIC
, stage_base='IV' as stage_IV
, stage_base='IV' and stage_ext like 'A%' as stage_IVA
, stage_base='IV' and stage_ext like 'B%' as stage_IVB
from stage
;
-- check
select *
from (select *, row_number() over (partition by stage
        order by person_id)
    from stage_checks)
where row_number=1
order by stage
;

/***
* lot: including mrn deduplicate
*/
create temporary table _lot as
select person_id, mrn, nvl(max(nvl(lot,0)),0) n_lot
from demo
join cplus_from_aplus.person_mrns using (person_id)
left join dev_patient_clinical_lca.line_of_therapy using (mrn)
group by person_id, mrn
;
-- 5028, 5007, 5007
select count(*), count(distinct person_id), count (distinct person_id::text + '|' + 'n_lot') from lot;

drop table if exists lot;
create table lot as
select distinct person_id, n_lot
from _lot
;

drop table if exists lot_checks;
create table lot_checks as
select person_id, n_lot
, n_lot=0 as lot_none, n_lot>=1 as lot_any
, n_lot=1 as lot_1, n_lot=2 as lot_2, n_lot=3 as lot_3
, n_lot>=4 as lot_ge_4
from lot
;

set search_path=ct_lca;
create table patient_attribute_lot as
select person_id, n_lot as patient_value
, attribute_id, attribute_group, attribute_name, value
, case value when '0' then n_lot=0
    when '1' then n_lot=1
    when '2' then n_lot=2
    when '3' then n_lot=3
    when '>=4' then n_lot>=4
    end as match
from lot
cross join attribute
where attribute_group='line of therapy'
;
-- check
select *
from (select *, row_number() over (partition by n_lot
        order by person_id)
    from lot_checks)
where row_number=1
order by n_lot
;
