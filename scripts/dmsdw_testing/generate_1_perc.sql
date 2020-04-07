/* generating a 1% subset of the dmsdw database
Require: dmsdw_2019q1
Results: dmsdw_testing
Algorithm:
    * gen a cohort of random 1% patients by mrn
    * filter by mrn
        d_person, d_encounter, d_demographics
    * filter by person_key
        fact, fact_lab, fact_eagle
    * filter by {}_group_key
        b_... tables
    * cp the full tables
        fd_... tables
        d_metadata, d_unit_of_measure, d_data_state
        d_time_of_day, d_calendar
*/
comment on schema ${working_schema} is 'A subset of dmsdw_2019q1 with 1% of patients for testing purpose.'
set search_path=${working_schema};

create table cohort as
with mrn_all as (
    select distinct medical_record_number
    from dmsdw_2019q1.d_person
)
select medical_record_number
from mrn_all
order by random()
limit 9383938/100
;
/*
-- select count(*) from mrn_all; --9383938
--limit (select count(*) from mrn_all)/100
select count(*) from cohort;
*/
------------------------------------------------------------
-- filter by mrn
create table d_person as
select * from dmsdw_2019q1.d_person
join cohort using (medical_record_number)
;
/*
select count(*), count(distinct medical_record_number)
from d_person;
    -- 460668, 93839
    -- avg 5 person_key for each patient
*/
create table d_encounter as
select * from dmsdw_2019q1.d_encounter
join cohort using (medical_record_number)
;
/*
select count(*), count(distinct medical_record_number)
from d_encounter;
    -- 460668, 41824
    -- avg 10 encounter for each patient
-- bugreport: half of the mrn donot have any encounter!!
*/
create table d_demographic as
select * from dmsdw_2019q1.d_demographic
join cohort using (medical_record_number)
;
/*
select count(*), count(distinct medical_record_number)
from d_demographic;
    -- 93839, 93839
*/

------------------------------------------------------------
-- filter by person_key
create table fact as
select t.* from dmsdw_2019q1.fact t
join d_person using (person_key);
/*
select count(*), count(distinct person_key)
from fact;
    -- 26641180 | 317756
    -- avg 100 facts for each person_key
    -- 20% of person_key have no facts
*/
create table fact_lab as
select t.* from dmsdw_2019q1.fact_lab t
join d_person using (person_key);
/*
select count(*), count(distinct person_key)
from fact_lab;
    -- 10384172 | 12583
    -- !!?? avg 1000 fact_lab for each person_key having lab
*/

create table fact_eagle as
select t.* from dmsdw_2019q1.fact_eagle t
join d_person using (person_key);
/*
select count(*), count(distinct person_key)
from fact_eagle;
    --  6996735 | 13494
    -- !!?? avg 500 fact_eagle for each person_key having lab
*/

------------------------------------------------------------ 
-- filter by group_key
create table b_diagnosis as
select t.* from dmsdw_2019q1.b_diagnosis t
join fact using (diagnosis_group_key);

create table b_material as
select t.* from dmsdw_2019q1.b_material t
join fact using (material_group_key);

create table b_procedure as
select t.* from dmsdw_2019q1.b_procedure t
join fact using (procedure_group_key);

create table b_caregiver as
select t.* from dmsdw_2019q1.b_caregiver t
join fact using (caregiver_group_key);

create table b_accounting as
select t.* from dmsdw_2019q1.b_accounting t
join fact using (accounting_group_key);

create table b_organization as
select t.* from dmsdw_2019q1.b_organization t
join fact using (organization_group_key);

create table b_payor as
select t.* from dmsdw_2019q1.b_payor t
join fact using (payor_group_key);

------------------------------------------------------------ -- copy the whole tables
create table fd_diagnosis as
select * from dmsdw_2019q1.fd_diagnosis
;
create table fd_material as
select * from dmsdw_2019q1.fd_material
;
create table fd_procedure as
select * from dmsdw_2019q1.fd_procedure
;
create table fd_caregiver as
select * from dmsdw_2019q1.fd_caregiver
;
create view fd_facility as
select * from dmsdw_2019q1.fd_facility
;
create view fd_accounting as
select * from dmsdw_2019q1.fd_accounting
;
create view fd_organization as
select * from dmsdw_2019q1.fd_organization
;
create view fd_payor as
select * from dmsdw_2019q1.fd_payor
;

-- d_metadata, d_unit_of_measure, d_data_state
-- d_time_of_day, d_calendar
create table d_metadata as
select * from dmsdw_2019q1.d_metadata
;
create table d_unit_of_measure as
select * from dmsdw_2019q1.d_unit_of_measure
;
create table d_data_state as
select * from dmsdw_2019q1.d_data_state
;
create table d_calendar as
select * from dmsdw_2019q1.d_calendar
;
create table d_time_of_day as
select * from dmsdw_2019q1.d_time_of_day
;
