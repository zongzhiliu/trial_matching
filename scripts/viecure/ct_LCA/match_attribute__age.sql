/*** match demo
Requires: demo (date_of_birth)
, crit_attribute_used (attribute_id)
, trial_attribute_used (ie_value)
Result: _pat_age
*/
drop table if exists _p_a_t_age;
create table _p_a_t_age as
select attribute_id, trial_id, person_id
, datediff(year, date_of_birth, current_date) as patient_value
, ie_value
, case attribute_id
    when 5 then patient_value >=12
    when 6 then patient_value >=18
    when 7 then patient_value >=20
    end as match
from trial_attribute_used
join crit_attribute_used using (attribute_id)
cross join demo
where attribute_id in (5, 6, 7)
;

create view qc_match_age as
select attribute_id, attribute_name, attribute_value, ie_value
, count(distinct person_id)
from _p_a_t_age join crit_attribute_used using (attribute_id)
where match
group by attribute_id, attribute_name, attribute_value, ie_value
order by attribute_id
;
-- select * from qc_match_age;