/***
Requires: master_match 
, trial_attribute_updated, crit_attribute_updated 
, trial_logic_levels
Results: master_sheet
Settings:
*/
drop view if exists master_sheet cascade;
create view master_sheet as
select trial_id, person_id, attribute_id
, attribute_group, attribute_name, attribute_value
, ie_value, ie_flag
, attribute_match
, mandatory, logic
, logic_l1, logic_l2
from master_match
join trial_attribute_updated using (attribute_id, trial_id)
join trial_logic_levels using (attribute_id, trial_id)
join crit_attribute_updated using (attribute_id)
order by person_id, trial_id, attribute_id
;
/*
select trial_id, person_id, count(*)
from master_sheet
where person_id::varchar like '%000'
group by trial_id, person_id
order by trial_id, person_id
limit 99
;
select * from master_sheet
limit 100;
select count(distinct person_id), count(distinct trial_id), count(distinct attribute_id) from v_master_sheet;

select count(*) from v_master_sheet; --20,172,318
select count(*) from (select distinct trial_id, person_id, attribute_id from v_master_sheet); --20, 119,807
*/

