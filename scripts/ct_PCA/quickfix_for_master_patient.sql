/* Quickfix so that cancer/master_patient can be run without modification
Requires: _master_match, crit_attribute_used
Results: _master_sheet (new), crit_attribute_used (modified), crit_attribute_used_raw (backup)
*/
alter table crit_attribute_used rename to crit_attribute_used_raw;
create table crit_attribute_used as
select attribute_id
, attribute_group, attribute_name, value attribute_value
, crit_id::varchar || '.or' as logic
from crit_attribute_used_raw
;

alter table trial_attribute_used rename to trial_attribute_used_raw;
create table trial_attribute_used as
select r.*
, mandatory_default as mandatory
from trial_attribute_used_raw r
join crit_attribute_used using (attribute_id)
;
