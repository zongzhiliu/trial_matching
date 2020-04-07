/***
 * demo/cohort
 Requires:
    cplus_from_aplus, prod_references, prod_msdw
 Results:
    cohort, demo, v_demo_w_zip
 Settings:
    cancer_type, last_visit_within
 */
drop table if exists demo cascade;
create table demo as
select distinct person_id, date_of_birth, gender_name, date_of_death, race_name, ethnicity_name
from cplus_from_aplus.cancer_diagnoses cd
join prod_references.cancer_types using (cancer_type_id)
join prod_references.people p using (person_id)
join prod_references.genders g using (gender_id)
join prod_references.races r using (race_id)
join prod_references.ethnicities using (ethnicity_id)
join cplus_from_aplus.visits using (person_id)
where nvl(cd.status, '') != 'deleted' and nvl(p.status, '') != 'deleted'
    and date_of_death is NULL
    and datediff(day, visit_date, '${protocal_date}')/365.25 <= ${last_visit_within}
    and cancer_type_name='${cancer_type}'
;

create or replace view cohort as select distinct person_id from demo;

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
/*qc
select count(*), count(distinct person_id) from demo;
    --13774
select count(*), count(distinct person_id) from demo_plus
-- where active_flag='Y'
;
select count(*), count(distinct person_id) from v_demo_w_zip
;
create or replace view ct_pca.v_debug_irregular_zip as
select person_id+3040 as person_id
, dz.address_zip zip_reported
, address_country, address_city, dp.address_zip, active_flag
from ct_pca.demo_new dz
join prod_references.person_mrns using (person_id)
join (select distinct medical_record_number mrn, citizenship
    , address_country, address_city, address_zip, active_flag, valid_flag
    from prod_msdw.d_person) dp using (mrn)
where nvl(dz.address_zip, '') !~ '^[-0-9]{3,}$' or dz.address_zip ~ '^0+$'
order by person_id, active_flag, dp.address_zip;

select address_zip from demo_new
where nvl(address_zip, '') !~ '^[-0-9]{3,}$' or address_zip ~ '^0+$'
;
*/
