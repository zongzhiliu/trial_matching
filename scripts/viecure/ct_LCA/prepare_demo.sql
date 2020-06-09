/*** create demo
Requires: ct.viecure.demo_plus 
, cohort
Result: demo
*/
drop table if exists demo cascade;
create table demo as
select distinct person_id, birth_date date_of_birth, gender_name, date_of_death, race_name, ethnicity_name, last_visit_date
from cohort
join viecure_ct.demo_plus using (person_id)
;
--qc
select count(distinct person_id) from demo; -- 1092

drop view if exists v_demo;
create view v_demo as select person_id
, decode(gender_name, 'F', 'Female', 'M', 'Male') gender_name
, date_trunc('month', date_of_birth) date_of_birth_truncated
, race_name
, ethnicity_name
, last_visit_date::date
from demo
order by last_visit_date desc nulls last
;

