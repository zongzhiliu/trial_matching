/*
Results: vital_bmi, latest_bmi
Requires: _person, {dmsdw}
*/
drop table if exists _vital;
create table _vital as
select distinct mrn
, f.age_in_days_key as age_in_days
, bp.procedure_role
, fp.procedure_description
, fp.context_procedure_code
, fp.context_name
, f.value
, u.unit_of_measure
, level2_event_name, level3_action_name, level4_field_name
from _person
join ${dmsdw}.fact f using (person_key)
join ${dmsdw}.d_metadata m using (meta_data_key)
join ${dmsdw}.b_procedure bp using (procedure_group_key)
join ${dmsdw}.fd_procedure fp using (procedure_key)
join ${dmsdw}.d_unit_of_measure u using (uom_key)
--join prod_msdw.d_encounter e using (encounter_key)
where level2_event_name like 'vital sign%'
    and level4_field_name='clinical result'
;

-- safe to only pick from EPIC (scott), uom is no problem, exclude 'Result' (scott), keep Vital Sign (RAS X02) for now

drop table if exists _vital_weight_height_by_day;
create table _vital_weight_height_by_day as
select mrn, age_in_days, procedure_description, value::float, level2_event_name, level3_action_name
from (select *, row_number() over(
        partition by mrn, age_in_days, procedure_description
        order by value::float desc nulls last, level2_event_name, level3_action_name)
    from _vital
    where procedure_description in ('WEIGHT', 'HEIGHT')
        and value ~ '^[0-9]+(\\.[0-9]+)?$'
        and context_name='EPIC')
where row_number=1
;
--select '71.' ~ '^[0-9]+(\\.[0-9]+)?$';
drop table if exists vital_bmi;
create table vital_bmi as
with w as (
    select mrn, age_in_days as weight_age, value as weight_kg
    from _vital_weight_height_by_day
    where procedure_description='WEIGHT'
), h as (
    select mrn, age_in_days as height_age, value as height_cm
    from _vital_weight_height_by_day
    where procedure_description='HEIGHT'
), hw as (
    select mrn, weight_age, weight_kg, height_age, height_cm
    from w
    join h using (mrn)
    where weight_age-height_age between 0 and 365
)
select mrn, weight_age, weight_kg
, height_age, height_cm/100 as height_m
, weight_kg/(height_m*height_m) as bmi
from hw
where height_m != 0 --quickfix: divide by zero error
;

drop table if exists latest_bmi;
create table latest_bmi as
select mrn, mrn person_id
, height_age, height_m
, weight_age, weight_kg
, bmi
from (select *, row_number() over (
        partition by mrn
        order by -weight_age, -height_age)
    from vital_bmi)
where row_number = 1
;
