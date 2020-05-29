/* a light version of all lab from msdw_lab and epic_lab
using: cohort, dmsdw.fact_lab, .epic_lab
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
select *, 'MSDW' as source_table
from _msdw_lab
UNION
select *, 'Epic' as source_table
from _epic_lab
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

-- mapp to loinc without unit conversion
drop table if exists loinc_lab cascade;
create table loinc_lab as
select al.*
, loinc, default_unit loinc_unit
from all_lab al
join resource.all_loinc_mappings_20191018
	on source_table=source and test_name=alias and test_code=code and unit_of_measure=unit --checklater: null
	where factor=1
;

