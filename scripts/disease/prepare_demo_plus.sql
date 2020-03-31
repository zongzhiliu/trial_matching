/*
Returns: demo_plus, v_demo_w_zip
Requires: demo, dmsdw
, reference.race_categories_map_to_name
, reference.ethnicity_code_map_to_name
*/
drop table if exists _demo_zip cascade;
create table _demo_zip as
select mrn, address_zip
from (select d.*, address_zip
    , row_number() over (
        partition by person_id
        order by active_flag)
    from demo d
    join ${dmsdw}.d_person dp on medical_record_number=mrn)
where row_number=1
;

drop table if exists _demo_race;
create table _demo_race as
select mrn, clean_name as race_name
from demo
join reference.race_categories_map_to_name
    on race_in_msdw = race_raw
;

drop table if exists _demo_ethnicity;
create table _demo_ethnicity as
select mrn, ethnicity
from demo
join reference.ethnicity_code_map_to_name
    on alias = ethnicity_raw
;
/*
select count(*), count(distinct mrn)
from _demo_zip;
from _demo_ethnicity;
from demo;
from _demo_race;
*/
drop table if exists demo_plus cascade;
create table demo_plus as
select  person_id, mrn
, initcap(gender) as gender
, dob_low date_of_birth_truncated --, d.date_of_death::date
, case race_name
    when 'Hispanic/Latino' then 'White'
    when 'Not Reported' then 'Unknown'
    else race_name
    end as race_name
, ethnicity
, address_zip
from demo
left join _demo_zip using (mrn)
left join _demo_race using (mrn)
left join _demo_ethnicity using (mrn)
;

drop view if exists v_demo_w_zip;
create or replace view v_demo_w_zip as
select person_id, gender, date_of_birth_truncated
, race_name, ethnicity, address_zip
from demo_plus
order by person_id
;

/*
select count(*), count(distinct mrn)
from demo_plus;
select * from v_demo_w_zip limit 99;
*/

