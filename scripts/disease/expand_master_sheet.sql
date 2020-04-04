-- run on the pharma server
-- Requires: working_schema, logic_cols, v_crit_attribute_used_new, v_master_sheet_n

use db_data_bridge;

alter table ${working_schema}_v_crit_attribute_used_new
    add index (new_attribute_id);
alter table ${working_schema}_v_master_sheet_n
    add index (new_attribute_id);
alter table ${working_schema}_v_master_sheet_n
    add index (new_attribute_id, trial_id, person_id);

drop table if exists ${working_schema}_master_sheet_new;
create table ${working_schema}_master_sheet_new as
select new_attribute_id, old_attribute_id
, trial_id, person_id
, attribute_group, attribute_name, attribute_value
, attribute_match
, inclusion, exclusion
, mandatory
, ${logic_cols}
from ${working_schema}_v_master_sheet_n m
join ${working_schema}_v_crit_attribute_used_new using (new_attribute_id)
order by person_id, trial_id, new_attribute_id
;
