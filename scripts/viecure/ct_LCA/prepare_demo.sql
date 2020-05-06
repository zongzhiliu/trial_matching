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
