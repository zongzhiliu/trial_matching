create view v_crit_attribute_expanded as
select attribute_id, attribute_group, attribute_name, attribute_value
from crit_attribute_used
order by attribute_id;

drop view if exists v_master_sheet_expanded;
create view v_master_sheet_expanded as
select person_id + 3040 as person_id
, ca.*, attribute_match::int
from v_crit_attribute_expanded ca
join master_match using (attribute_id)
order by person_id, attribute_id
;

