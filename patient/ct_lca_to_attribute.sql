/*dependencies
crit_attribute
gene_alterations
ref_drug_mapping
ref_histology_category
ref_lab_mapping
*/
-- @set cancer_type=LCA
-- @set cancer_type_icd=^(C34|162)
set search_path=ct_{cancer_type};
create view ref_drug_mapping as
select * from ct.drug_mapping_cat_expn3
;
create view ref_lab_mapping as
select * from ct.ref_lab_loinc_mapping
;

/***
* age calc from dob
*/
drop table if exists _p_a_age;
create table _p_a_age as
select person_id
, datediff(day, date_of_birth, current_date)/365.25 as patient_value
, attribute_id --, attribute_group, attribute_name, value
, case attribute_id
    when 5 then patient_value >=12
    when 6 then patient_value >=18
    when 7 then patient_value >=20
    when 8 then patient_value <=75
    end as match
from demo
cross join crit_attribute
where attribute_id in (5,6,7,8) --attribute_group='demographic' later
;
*/
/*-- check
select attribute_name, value, count(*)
from _p_a_age join crit_attribute using (attribute_id)
where match
group by attribute_name, value
order by attribute_name, value
;
*/


/***
 * histology mapped
 * histology mapping file to be merged
 */
drop table if exists _p_a_histology cascade;
create table _p_a_histology as
select person_id, histologic_type_name as patient_value
, attribute_id
, case attribute_id
    when 1 then nsclc
    when 2 then nsclc and squamous
    when 3 then nsclc and non_squamous
    when 4 then sclc
    --when 402 then non_small_cell_adenocarcinoma
    --when 419 then small_cell_carcinoma
    --when 420 then neuroendocrine_carcinoma
    end as match
from histology h
join ref_histology_category m using (histologic_type_name)
cross join crit_attribute
where lower(attribute_group)='histology'
;
/*-- check
select attribute_name, value, count(*)
from _p_a_histology join crit_attribute ca using (attribute_id)
where match
group by attribute_name, value
order by attribute_name, value
;
*/

/***
 * patient_attibute combined
 */ 
create or replace view _p_a_match as
    select person_id, attribute_id, match, patient_value::varchar from _p_a_age
    union select person_id, attribute_id, match, patient_value::varchar from _p_a_ecog
    union select person_id, attribute_id, match, patient_value::varchar from _p_a_karnofsky
    union select person_id, attribute_id, match, patient_value::varchar from _p_a_stage
    union select person_id, attribute_id, match, patient_value::varchar from _p_a_histology
    union select person_id, attribute_id, match, patient_value::varchar from _p_a_mutation
    union select person_id, attribute_id, match, patient_value::varchar from _p_a_lot
    union select person_id, attribute_id, match, patient_value::varchar from _p_a_chemotherapy
    union select person_id, attribute_id, match, patient_value::varchar from _p_a_immunotherapy
    union select person_id, attribute_id, match, patient_value::varchar from _p_a_targetedtherapy
    union select person_id, attribute_id, match, patient_value::varchar from _p_a_hormone_therapy
    union select person_id, attribute_id, match, patient_value::varchar from _p_a_lab
    union select person_id, attribute_id, match, patient_value::varchar from _p_a_disease
;


