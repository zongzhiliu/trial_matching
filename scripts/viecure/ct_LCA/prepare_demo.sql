/*** Results: demo
Requires:
    viecure_ct: demo_plus
*/
drop table if exists demo cascade;
create table demo as
select distinct person_id, date_of_birth, gender_name, date_of_death, race_name, ethnicity_name
from cohort
join viecure_ct.demo_plus using (person_id)
;

/*qc
*/
