/***
 * cohort
 Requires:
    viecure_ct: demo_plus, cancer_dx
 Results:
    cohort
*/
drop table if exists cohort cascade;
create table cohort as
select distinct person_id
from viecure_ct.cancer_dx cd
join viecure_ct.demo_plus d using (person_id)
where cancer_type_name=${cancer_type}
    and date_of_death is NULL
    and datediff(day, last_visit_date, '${protocal_date}')/365.25 <= ${last_visit_within}
;

