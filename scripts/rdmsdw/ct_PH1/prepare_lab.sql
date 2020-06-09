/*** * labs
Requires: cohort
    , ct.all_labs
Results:
    loinc_lab, latest_lab
*/
create temporary table _msdw_lab as
with mloinc1 as (
    select * from resource.all_loinc_mappings_20191018
    where lm.source='MSDW' and lm.factor=1
        and loinc='48642-3'
), plab as (
    select mrn, age_in_days_key as age_in_days
    , procedure_description as test_name
    , context_procedure_code as test_code
    , level3_action_name as lab_status
    , level4_field_name as result_status
    , value as test_result_value
    , unit_of_measure
    from (cohort
    join ${dmsdw}.d_person on mrn=medical_record_number)
    join ${dmsdw}.fact_lab using (person_key)
    join ${dmsdw}.d_metadata using (meta_data_key)
    join ${dmsdw}.d_unit_of_measure using (uom_key)
    join ${dmsdw}.b_procedure using (procedure_group_key)
    join ${dmsdw}.fd_procedure using (procedure_key)
    join resource.all_loinc_mappings_20191018
    where procedure_role='Result'  -- to expand later
        and level1_context_name='SCC'
        and level2_event_name='Lab Test'
        and level3_action_name ~ '(Other|Final|Preliminary|Corrected) Result'
        and level4_field_name ~ 'Clinical Result (Numeric|String)'
)
select distinct mrn, age_in_days
, test_name, test_code, unit_of_measure
, result_status, test_result_value
from tmp
join mloinc1 on test_name=alias and test_code=code and unit_of_measure=unit
;



drop table if exists loinc_lab;
create table loinc_lab as
select distinct mrn
, age_in_days_key::float as age_in_days  -- they are minus and floats??
, loinc_code, loinc_display_name
, value_float, value_range_low, value_range_high, unit
, source_value, source_unit
from ct.all_labs
join cohort using (mrn)
where loinc_code is not null
    and value_float is not null
;

drop table if exists latest_lab;
create table latest_lab as
select mrn person_id
, dateadd(day, age_in_days::int, date_of_birth)::date result_date
, loinc_code, loinc_display_name
, value_float, unit
, source_unit, source_value
from (select *, row_number() over (
        partition by mrn, loinc_code
        order by age_in_days desc nulls last, value_float desc nulls last)
    from loinc_lab)
join demo using (mrn)
where row_number=1
--order by mrn, age_in_days, loinc_code
;

/*** qc
create table _all_loinc as
select distinct loinc_code, loinc_display_name, unit
from latest_lab
;

select count(distinct person_id) from latest_lab; --11417
select * from _all_loinc where lower(loinc_display_name) ~ 'testosterone'; --'prostate';
*/

