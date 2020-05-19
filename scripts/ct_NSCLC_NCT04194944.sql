/* ad hoc analysis with RET fusion as a driver mutation
*/
set search_path=ct_nsclc;
select * from trial_attribute_used join crit_attribute_used using (attribute_id)  where trial_id='NCT04194944' order by attribute_id;
    -- bug: RET is in a or group with !EGFR, !ALK, !ROS1, !BRAF, !KRAS
    -- fixlater: remove the logic; mandatory if inc; play more on False/NULL

select attribute_match, inclusion, mandatory, logic_l1_id, count(*)
from v_master_sheet_new
where old_attribute_id=108 --RET fusion
group by attribute_match, inclusion, mandatory, logic_l1_id
;
/*
  0                 | 0           | 1           | 96.or         | 2214    |
  0                 | 1           | 1           | 96.or         | 7380  
*/

create temporary table _var as
select person_id, genetic_test_name, gene
, variant_type
, variant
, variant_display_name
, reported_occurrence_type
from cohort
join cplus_from_aplus.genetic_test_occurrences using (person_id)
join cplus_from_aplus.genetic_tests using (genetic_test_id)
join cplus_from_aplus.variant_occurrences using (genetic_test_occurrence_id)
join cplus_from_aplus.target_genes using (target_gene_id) --, genetic_test_id)
where is_clinically_significant
;
/*
select * from _var limit 99;
select * from _var
where gene='RET' -- ilike '%RET%'
limit 99;
*/
select *
from _var
join cplus_from_aplus.cancer_diagnoses using (person_id)
where gene='RET';

select person_id, genetic_test_name, gene, variant_type, variant
, (year_of_diagnosis::varchar + '-' + month_of_diagnosis::varchar + '-' + day_of_diagnosis::varchar)::date as diagnosis_date
, overall_stage, status
, histologic_type_name, histologic_icdo
, primary_site_display_name, primary_site_icd10_code
from _var
join cplus_from_aplus.cancer_diagnoses using (person_id)
join prod_references.histologic_types using (histologic_type_id)
join prod_references.primary_sites using (primary_site_id)
where gene='RET';

drop view var;
create view var as
with counts as (
    select genetic_test_name, reported_occurrence_type, gene
    , nvl(variant_type, '') variant_type
    , count(*) records, count(distinct person_id) patients
    from _var
    group by genetic_test_name, reported_occurrence_type, gene, variant_type
),  vars as (
    select genetic_test_name, reported_occurrence_type, gene
    , nvl(variant_type, '') variant_type
    , listagg(distinct nvl(variant,''), '| ') within group (order by variant) variants
    from _var
    group by genetic_test_name, reported_occurrence_type, gene, variant_type
)
select genetic_test_name, reported_occurrence_type, gene, variant_type
, records, patients, variants
from vars
join counts using (genetic_test_name, reported_occurrence_type, gene, variant_type)
order by genetic_test_name, reported_occurrence_type, gene, variant_type
;

select * from var where variant_type='';
-- total patients with any RET alterations
create view ct._all_ret_alterations as
select person_id, cancer_type_name
, genetic_test_name, gene
, variant_type
, variant
, variant_display_name
, reported_occurrence_type
, is_clinically_significant
, cd.status cdx_status
-- , p.status patient_status , p.date_of_death
from cplus_from_aplus.cancer_diagnoses cd
join cplus_from_aplus.cancer_types using (cancer_type_id)
--join cplus_from_aplus.people p using (person_id)
join cplus_from_aplus.genetic_test_occurrences using (person_id)
join cplus_from_aplus.genetic_tests using (genetic_test_id)
join cplus_from_aplus.variant_occurrences using (genetic_test_occurrence_id)
join cplus_from_aplus.target_genes using (target_gene_id) --, genetic_test_id)
where gene='RET'
order by cancer_type_name, variant_type
;

--create view ct._all_ret_alterations as
select person_id --, cancer_type_name
, genetic_test_name, gene
, variant_type
, variant
, variant_display_name
, reported_occurrence_type
, is_clinically_significant
-- , cd.status cdx_status
-- , p.status patient_status , p.date_of_death
--from cplus_from_aplus.cancer_diagnoses cd
--join cplus_from_aplus.cancer_types using (cancer_type_id)
--join cplus_from_aplus.people p using (person_id)
from cplus_from_aplus.genetic_test_occurrences --using (person_id)
join cplus_from_aplus.genetic_tests using (genetic_test_id)
join cplus_from_aplus.variant_occurrences using (genetic_test_occurrence_id)
join cplus_from_aplus.target_genes using (target_gene_id) --, genetic_test_id)
where gene ~ 'BTK'
order by variant_type
--order by cancer_type_name, variant_type
;

-- what type of cancer do they have?
select person_id, listagg(distinct cancer_type_name, '| ')
from (select distinct  person_id, context_diagnosis_code from dev_patient_info_pan.all_diagnosis
    join cplus_from_aplus.person_mrns on medical_record_number=mrn
    where person_id in ( 185613, 182232)
)
join (select * from ct.ref_cancer_icd where cancer_type_name!='PAN') 
    on ct.py_contains(nvl(context_diagnosis_code, ''), icd_9) or ct.py_contains(nvl(context_diagnosis_code, ''), icd_10)
group by person_id
;
