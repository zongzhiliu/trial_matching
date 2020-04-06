------------------------------------------------------------
-- filter by mrn
create table d_person as
select * from prod_msdw.d_person
join cohort using (medical_record_number)
;
/*
select count(*), count(distinct medical_record_number)
from d_person;
    -- 57863, 1888
    -- avg 30 person_key for each patient
*/
create table d_encounter as
select * from prod_msdw.d_encounter
join cohort using (medical_record_number)
;
/*
select count(*), count(distinct medical_record_number)
from d_encounter;
    -- 260600, 1888
    -- avg 100 encounter for each patient
*/

------------------------------------------------------------ -- filter by person_id
create table all_labs as
select t.* from prod_msdw.all_labs t
join d_person on mrn=medical_record_number
;
