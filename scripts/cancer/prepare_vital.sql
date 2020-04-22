/***
Results: vital, vital_bmi
Requires: cohort, dev_patient_info
 */
drop table if exists vital;
create table vital as
select distinct person_id
    , age_in_days
    , procedure_role
    , procedure_description
    , context_procedure_code
    , context_name
    , value
    , unit_of_measure
from cohort
join prod_references.person_mrns using (person_id)
join dev_patient_info_${cancer_type}.vitals on (medical_record_number=mrn)
;

create temporary table _vital_weight_height_by_day as
select person_id, age_in_days, procedure_description
, value::float
from (select *, row_number() over(
        partition by person_id, age_in_days, procedure_description
        order by value::float desc nulls last, context_name)
    from vital
    where procedure_description in ('WEIGHT', 'HEIGHT')
        and value ~ '^[0-9]+([.][0-9]+)?$'
        and context_name='EPIC')
where row_number=1
;

drop table if exists vital_bmi;
create table vital_bmi as
with w as (
    select person_id, age_in_days as weight_age, value as weight_kg
    from _vital_weight_height_by_day
    where procedure_description='WEIGHT'
), h as (
    select person_id, age_in_days as height_age, value as height_cm
    from _vital_weight_height_by_day
    where procedure_description='HEIGHT'
), hw as (
    select person_id, weight_age, weight_kg, height_age, height_cm
    from w
    join h using (person_id)
    where weight_age-height_age between 0 and 365
)
select person_id, weight_age, weight_kg
, height_age, height_cm/100 as height_m
, weight_kg/(height_m*height_m) as bmi
from (select *, row_number() over (
        partition by person_id, weight_age
        order by height_age desc nulls last)
    from hw)
where row_number=1
order by person_id, weight_age
;

create view qc_vital as
select  context_name, context_procedure_code, procedure_description, unit_of_measure
, count(*) records, count(distinct person_id) patients
from vital
group by context_name, context_procedure_code, procedure_description, unit_of_measure
;
select count(*) measures from qc_vital
;
select count(*) records, count(distinct person_id) patients
from vital
;
