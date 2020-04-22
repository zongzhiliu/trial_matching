/***
 * cohort
 Requires:
    cplus_from_aplus, prod_references, prod_msdw
 Results:
    cohort
*/
drop table if exists cohort cascade;
create table cohort as
select distinct person_id
from cplus_from_aplus.cancer_diagnoses cd
join prod_references.cancer_types using (cancer_type_id)
join prod_references.people p using (person_id)
join cplus_from_aplus.visits using (person_id)
where nvl(cd.status, '') not like '%deleted' and nvl(p.status, '') not like '%deleted'
    and date_of_death is NULL
    and datediff(day, visit_date, '${protocal_date}')/365.25 <= ${last_visit_within}
    and cancer_type_name='${cancer_type}'
;

