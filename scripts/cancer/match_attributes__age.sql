/***
* match demographics
*/
drop table if exists _p_a_t_age;
create table _p_a_t_age as
select attribute_id, trial_id, person_id
, datediff(day, date_of_birth, '${protocal_date}')/365.25 as patient_value
, ie_value::int as value
, case attribute_id
    when 205 --'Min_age
        then patient_value>=value
    when 206 --'Max_age
        then patient_value<=value
    end as match
from trial_attribute_used
join crit_attribute_used using (attribute_id)
cross join demo
where attribute_id in (205, 206)
;
/* check
select attribute_name, attribute_value, clusion, count(distinct person_id)
from _p_a_t_age join crit_attribute_used using (attribute_id)
where match
group by attribute_name, attribute_value, clusion
order by attribute_name, attribute_value, clusion::int
;
*/

