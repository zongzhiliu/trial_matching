/*** match line_of_therapy
 Requires: lot
 , crit_attribute_used (attribute_id and _value)
 Results: _p_a_lot
 */
drop table if exists _p_a_lot cascade;
create table _p_a_lot as
select person_id, n_lot as patient_value
, attribute_id
, case
    when attribute_id between 147 and 150 then n_lot=attribute_value::int
    when attribute_id=151 then n_lot>=4
    end as match
from lot
cross join crit_attribute_used
where attribute_id between 147 and 151
;

create view qc_match_lot as
select attribute_name, attribute_value, count(*)
from _p_a_lot join crit_attribute_used ca using (attribute_id)
where match
group by attribute_name, attribute_value
order by attribute_name, attribute_value
;
