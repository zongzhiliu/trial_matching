drop table if exists _p_a_disease_status cascade;
create table _p_a_disease_status as
select person_id, NULL as patient_value
, attribute_id
, case attribute_id
    when 46 then
        bool_or(icd_code ~ '^(C7[789B]|19[678])')
    end as match
from _all_dx
cross join crit_attribute_used
where attribute_id = 46
group by attribute_id, person_id
;
/*
select match, count(*) patients
from _p_a_disease_status
group by match
;
t     |     1324
f     |    12436
*/
