/***
 * demo/cohort
 Requires:
    cplus_from_aplus, prod_references, prod_msdw
 Results:
    cohort, demo, v_demo_w_zip
 */
drop table if exists demo cascade;
create table demo as
select distinct person_id, date_of_birth, gender_name, date_of_death, race_name, ethnicity_name
from cohort
join prod_references.people p using (person_id)
join prod_references.genders g using (gender_id)
join prod_references.races r using (race_id)
join prod_references.ethnicities using (ethnicity_id)
;

-- demo with zip
drop table if exists demo_plus cascade;
create table demo_plus as
select *
from (select d.*, address_zip, active_flag
    , row_number() over (
        partition by person_id
        order by active_flag)
    from demo d
    join prod_references.person_mrns pm using(person_id)
    left join prod_msdw.d_person dp on dp.medical_record_number = pm.mrn)
where row_number=1
; --without left join, will lose persons
 --active_flag='Y'
-- replace with caregiver

drop view if exists v_demo_w_zip;
create view v_demo_w_zip as
select distinct person_id+3040 as person_id, d.gender_name
, date_trunc('month', d.date_of_birth)::date date_of_birth_truncated
, case when d.race_name='Not Reported' then
    'Unknown' else d.race_name end as race_name
, d.ethnicity_name
, substring(d.address_zip, 1, 3) address_zip
from demo_plus d
order by person_id
;

select count(*), count(distinct person_id) from demo;
/*qc
select count(*), count(distinct person_id) from demo_plus
-- where active_flag='Y'
;
select count(*), count(distinct person_id) from v_demo_w_zip
;
*/
