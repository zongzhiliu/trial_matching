-- cohort, demo, histology, stage
demo_plus: person_id
, date_of_birth, gender_name, race_name, ethnicity_name
, address_zip, date_of_death, last_visit_date

cancer_dx: person_id, cancer_type_name, cancer_type_icd
, histologic_type_name, histologic_icdo
, overall_stage, imputed_stage

-- dx
patient_dx: person_id, dx_date, icd, icd_code, description

-- test
select distinct person_id, result_date::date
, loinc_code, loinc_display_name
, value_float, unit
, source_value, source_unit
from prod_msdw.all_labs
join cohort using (person_id)
where loinc_code is not null
    and value_float is not null

