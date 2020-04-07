/* generating a 1% subset of the dmsdw database
Require: prod_msdw
Results: imsdw_testing
Algorithm:
    * gen a cohort of random 1% patients by mrn
    * filter by mrn
        d_person, d_encounter, d_demographics
    * filter by person_key
        fact, fact_lab, fact_eagle
    * filter by {}_group_key
        b_... tables
    * cp the full tables/views
        fd_... tables
        d_metadata, d_unit_of_measure, d_data_state
        d_time_of_day, d_calendar
    * filter by person_id
        all_labs
*/
create schema if not exists ${working_schema};
comment on schema ${working_schema} is 'A subset of prod_msdw with 1% of patients for testing purpose.'

create table cohort as
with mrn_all as (
    select distinct medical_record_number
    from prod_msdw.d_person
)
select medical_record_number
from mrn_all
order by random()
limit 188873/100
;
/*
select count(*) from mrn_all;
--188873
--limit (select count(*) from mrn_all)/100
select count(*) from cohort;
*/
