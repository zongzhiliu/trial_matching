/* a light version of all lab from msdw_lab and epic_lab

using: cohort
*/
create temporary table _msdw_lab as
select distinct mrn, age_in_days_key as age_in_days
, procedure_description as test_name
, context_procedure_code as test_code
, level3_action_name as lab_status
, level4_field_name as result_status
, value as test_result_value
, unit_of_measure
from (cohort
join ${dmsdw}.d_person on mrn=medical_record_number)
join ${dmsdw}.fact_lab using (person_key)
join ${dmsdw}.d_metadata using (meta_data_key)
join ${dmsdw}.d_unit_of_measure using (uom_key)
join ${dmsdw}.b_procedure using (procedure_group_key)
join ${dmsdw}.fd_procedure using (procedure_key)
where procedure_role='Result'  -- to expand later
	and level1_context_name='SCC'
	and level2_event_name='Lab Test'
	and level3_action_name ~ '(Other|Final|Preliminary|Corrected) Result'
	and level4_field_name ~ 'Clinical Result (Numeric|String)'
;
create temporary table _epic_lab as
select distinct mrn, (age_in_days_key::float)::int as age_in_days
, test_name
, test_code::text test_code
, lab_status
, result_status
, test_result_value
, unit_of_measurement as unit_of_measure
from cohort
join ${dmsdw}.epic_lab using(mrn)
;

create temporary table _all_lab AS
select *, 'scc_lab' as source_table
from ct_scd._scc_lab
UNION
select *, 'epic_lab' as source_table
from ct_scd._epic_lab
;

-- deduplicate
create table all_lab as
select *
from (select *, row_number() over(
		partition by mrn, age_in_days, test_name, test_result_value,unit_of_measure
		order by source_table, test_code, lab_status, result_status)
	from _all_lab)
where row_number=1
	and test_result_value is not null
;
