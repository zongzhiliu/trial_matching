/***
* sickle cell anemia/disease
*/

CREATE SCHEMA ct_SCD;
set search_path=ct_scd;
show search_path;
/***
 * cohort
 */
set search_path=dmsdw_2019q1;

-- diagnosis_role, diagnosis_rank, diagnosis_weighting_factor
drop view tmp;

drop table ct_scd.ref_dx_code_filtering;
create table ct_scd.ref_dx_code_filtering as
select context_name, context_diagnosis_code context_code, lower(description) description, count(*) records  --diagnosis_role, diagnosis_weighting_factor, 
from fd_diagnosis rb
join b_diagnosis bd using (diagnosis_key)
where lower(rb.description) ~ 'sickle cell|scd'
	and lower(context_name) ~ 'icd|imo'
group by context_name, context_code, description
order by context_name, context_code, description
;
select * from ct_scd.ref_dx_code_filtering
order by context_name, context_code, description
;

select context_name, context_diagnosis_code context_code
, lower(rd.description) description, count(distinct medical_record_number) patients
from D_PERSON
join FACT using (person_key)
join B_DIAGNOSIS using (diagnosis_group_key)
join fd_DIAGNOSIS rd using (diagnosis_key)
where lower(description) ~ 'sickle\\Wcell'
group by context_name, context_code, description
order by context_name, context_code, description
;

-- sickle\\Wcell: 11204
-- ICD w/crisis: 1371, excluded SD/SE: 1334
-- only one icd code: 134
create table ct_scd.mrn as
select medical_record_number mrn, count(*) n_icd
from D_PERSON
join FACT using (person_key)
join B_DIAGNOSIS using (diagnosis_group_key)
join fd_DIAGNOSIS rd using (diagnosis_key)
where context_name like 'ICD%' and context_diagnosis_code ~ 'D57\\.(0|[24]1).*|282\\.(62|64|42).*'
group by mrn
;

select count(*) from ct_scd.mrn;

/***
 * demo
 */
--select count(*), count(distinct medical_record_number)
set search_path=dmsdw_2019q1;
create temporary table _demo as
select person_key, person_control_key, mrn
, date_of_birth, month_of_birth
, gender, race, patient_ethnic_group, deceased_indicator
from d_person
join ct_scd.mrn on mrn=medical_record_number
where active_flag='Y'
;
select count(*), count(distinct mrn)
from _demo;
-- 1334, 1334 great!

select gender, count(*)
from _demo
group by gender;
	-- male 594, female 737, N/A 2, indeterminant 1

select race, count(*)
from _demo
group by race;
	-- toomany to be mapped
	
select patient_ethnic_group, count(*)
from _demo
group by patient_ethnic_group;
	-- toomany to be mapped

select deceased_indicator, count(*)
from _demo
group by deceased_indicator;
--		428
-- Yes	28
-- No	872
-- NOT AVAILABLE	6

drop table if exists ct_scd.demo;
create table ct_scd.demo as
select mrn
, TO_DATE(datepart(year, date_of_birth) || '-' || month_of_birth, 'yyyy-month') dob_low, last_day(dob_low) as dob_high
, datepart(year, dob_low) dob_year, datepart(month, dob_low) dob_month
, race race_raw, patient_ethnic_group ethnicity_raw
, case gender
	when 'Male' then 'male'
	when 'Female' then 'female'
	end as gender
, case deceased_indicator
	when 'Yes' then True
	when 'No' then False
	end as deceased
from _demo
where (deceased is null or deceased != 'Yes') -- already deceased
	and datediff(year, dob_low, current_date)<130 -- impossible birthdate
;

select count(*) from ct_scd.demo;

create table ct_scd.demo_age_now_20191105 as
select mrn, floor(datediff(day, dob_low, current_date) / 365.21) as age_now
from ct_scd.demo
;
select * from ct_scd.demo_age_now_20191104;
-- <=10:76, 953:3, null:2


/***
 * dx
 */
set search_path=dmsdw_2019q1;
drop table if exists _dx;
create temporary table _dx as
select distinct mrn
, age_in_days_key as age_in_days
, DESCRIPTION -- , diagnosis_type: same as context_name --, rd.active_flag
, context_diagnosis_code, context_name
, diagnosis_role, diagnosis_weighting_factor
from (d_person dp
join ct_scd.demo on medical_record_number=mrn)
join fact using (person_key)
join b_diagnosis using (diagnosis_group_key)
join fd_diagnosis rd using (diagnosis_key)
;

drop table if exists ct_scd.dx;
create table ct_scd.dx as
select *
from _dx
where context_name in ('ICD-10', 'ICD-9') --, 'IMO', 'MSDRG', 'APRDRG', 'APRDRG MDC', 'NYDRG', 'DRG','TDS')
order by mrn, age_in_days, context_name
;
select count(distinct mrn)
from ct_scd.dx
;


/***
 * vital
 */

create table ct_scd._vital as
select distinct mrn
	, f.age_in_days_key as age_in_days
    , bp.procedure_role
    , fp.procedure_description
    , fp.context_procedure_code
    , fp.context_name
    , f.value
    , u.unit_of_measure
    , level2_event_name, level3_action_name, level4_field_name
from (d_person dp join ct_scd.demo on (medical_record_number=mrn))
join fact f using (person_key)
join d_metadata m using (meta_data_key)
join b_procedure bp using (procedure_group_key)
join fd_procedure fp using (procedure_key)
join D_UNIT_OF_MEASURE u using (uom_key)
--join prod_msdw.D_ENCOUNTER E using (encounter_key)
where level2_event_name like 'Vital Sign%'
	and LEVEL4_FIELD_NAME='Clinical Result'
;

create table ct_scd.vital as
select v.*
from ct_scd._vital v
join ct_scd.demo using (mrn)
;


-- safe to only pick from EPIC (scott), uom is no problem, exclude 'Result' (scott), keep Vital Sign (RAS X02) for now
create table ct_scd._vital_weight_height_by_day as
select mrn, age_in_days, procedure_description, value::float, level2_event_name, level3_action_name
from (select *, row_number() over(
		partition by mrn, age_in_days, procedure_description
		order by value::float desc nulls last, level2_event_name, level3_action_name)
	from ct_scd._vital
	where procedure_description in ('WEIGHT', 'HEIGHT')
		and value ~ '^[0-9]+(\\.[0-9]+)?$'
		and context_name='EPIC')
where row_number=1
;
--select '71.' ~ '^[0-9]+(\\.[0-9]+)?$';
create table ct_scd.vital_bmi as
with w as (
	select mrn, age_in_days as weight_age, value as weight_kg
	from ct_scd._vital_weight_height_by_day
	where procedure_description='WEIGHT'
), h as (
	select mrn, age_in_days as height_age, value as height_cm
	from ct_scd._vital_weight_height_by_day
	where procedure_description='HEIGHT'
), hw as (
	select mrn, weight_age, weight_kg, height_age, height_cm	
	from w
	join h using (mrn)
	where weight_age-height_age between 0 and 365
)
select mrn, weight_age, weight_kg, height_age, height_cm/100 as height_m, weight_kg/(height_m*height_m) as bmi
from (select *, row_number() over (
		partition by mrn, weight_age
		order by height_age desc nulls last)
	from hw)
where row_number=1
order by mrn, weight_age
;

/***
 * sochx
 */
-- socialHx (Tobacco, alcohol, sexual, illicit drug, ...)
-- weekly_low >= 24 is defined as abuse, e.g.  beer or wine we don't know yet

set search_path=dmsdw_2019q1;
create table ct_scd._sochx as
select distinct mrn
, age_in_days_key as age_in_days
, level3_action_name, level4_field_name
, value, unit_of_measure
from (d_person dp
join ct_scd.demo on (medical_record_number=mrn))
join fact f using (person_key)
join d_metadata m using (meta_data_key)
join D_UNIT_OF_MEASURE using (uom_key)
where level2_event_name='Social History' 
;

create table ct_scd.sochx_alcohol as
select mrn, age_in_days, value::float as weekly_high, unit_of_measure
from (
	select *, row_number() over (
			partition by mrn
			order by value::float desc nulls last, unit_of_measure, age_in_days)
		from ct_scd._sochx
		where level3_action_name='Alcohol'
			and level4_field_name='Weekly High'
)
where row_number=1
;
create view ct_scd.v_gendar_alcohol as
select mrn, gender, weekly_high
from ct_scd.demo
left join ct_scd.sochx_alcohol using (mrn)
where gender in ('Male', 'Female')
;


/***
 * proc: surg
 */
set search_path=dmsdw_2019q1;

--create table ct_scd._proc as
create table ct_scd._kinds_of_procedures as
select distinct -- mrn
	-- , f.age_in_days_key as age_in_days
    bp.procedure_role
    , fp.procedure_description
    , fp.context_procedure_code
    , fp.context_name
    -- , f.value
    -- , u.unit_of_measure
    , level2_event_name, level3_action_name, level4_field_name, value
from (d_person dp
join ct_scd.demo on (medical_record_number=mrn))
join fact f using (person_key)
join d_metadata m using (meta_data_key)
--join d_unit_of_measure u using (uom_key)
join b_procedure bp using (procedure_group_key)
join fd_procedure fp using (procedure_key)
--join prod_msdw.D_ENCOUNTER E using (encounter_key)
;

select * from fact
limit 10;
create table ct_scd._surg as
select distinct mrn
	, f.age_in_days_key as age_in_days
    , bp.procedure_role
    , fp.procedure_description
    , fp.context_procedure_code
    , fp.context_name
    , f.value
    , u.unit_of_measure
    , level2_event_name, level3_action_name, level4_field_name
from (d_person dp
join ct_scd.demo on (medical_record_number=mrn))
join fact f using (person_key)
join d_metadata m using (meta_data_key)
join d_unit_of_measure u using (uom_key)
join b_procedure bp using (procedure_group_key)
join fd_procedure fp using (procedure_key)
--join D_ENCOUNTER E using (encounter_key)
where lower(procedure_role)~'surg' or lower(level2_event_name) ~ 'surg'
;

select mrn, age_in_days, procedure_description, level2_event_name, level3_action_name, level4_field_name
, value, unit_of_measure, context_name, context_procedure_code
from ct_scd._surg
order by mrn, age_in_days, procedure_description, level2_event_name, level3_action_name, level4_field_name
;

create table ct_scd.surg as
select mrn, age_in_days, context_procedure_code, context_name, procedure_description, level2_event_name
, listagg(level3_action_name, ' |') within group (order by level3_action_name) level3_action_names
, count(*) records
from ct_scd._surg
group by mrn, age_in_days, context_procedure_code, context_name, procedure_description, level2_event_name
order by mrn, age_in_days, context_procedure_code, context_name, procedure_description, level2_event_name
;

--create table ct_scd.last_procedure as
create table ct_scd._proc as (
	select mrn
		, f.age_in_days_key as age_in_days
	    , bp.procedure_role
	    , fp.procedure_description
	    , fp.context_procedure_code
	    , fp.context_name
	    , f.value
	    , u.unit_of_measure
	    , level2_event_name, level3_action_name, level4_field_name
	from (d_person dp
		join ct_scd.demo on (medical_record_number=mrn))
	join fact f using (person_key)
	join d_metadata m using (meta_data_key)
	join d_unit_of_measure u using (uom_key)
	join b_procedure bp using (procedure_group_key)
	join fd_procedure fp using (procedure_key)
	--join D_ENCOUNTER E using (encounter_key)
	--where lower(procedure_role)~'surg' or lower(level2_event_name) ~ 'surg'
)
;

--create table ct_scd._proc as select * from _proc;
create table ct_scd.latest_proc AS
select mrn, age_in_days, procedure_description, context_name, context_procedure_code, procedure_role
, level2_event_name, level3_action_name, level4_field_name, value, unit_of_measure
from (select *, row_number() over (
		partition by mrn, procedure_description
		order by -age_in_days, context_name, context_procedure_code, procedure_role
		, level2_event_name, level3_action_name, level4_field_name
		, value, unit_of_measure)
	from ct_scd._proc
	where level3_action_name not in ('Canceled', 'Pended') -- more later
)
where row_number=1
;
/***
 * lab
 */
set search_path=dmsdw_2019q1;
-- the current selection
select *
from d_metadata
where --meta_data_key in ('516','517', '524', '525', '532', '533',  '466')
	level2_event_name='Lab Test'
	and level1_context_name='SCC'
	and level3_action_name ~ '(Other|Final|Preliminary|Corrected) Result'
	and level4_field_name ~ 'Clinical Result (Numeric|String)'
;

-- expand the selection later
create table ct_scd._scc_lab as
select distinct mrn, age_in_days_key as age_in_days
, procedure_description as test_name
, context_procedure_code as test_code
, level3_action_name as lab_status
, level4_field_name as result_status
, value as test_result_value
, unit_of_measure
from (ct_scd.demo join d_person on mrn=medical_record_number)
join fact_lab using (person_key)
join d_metadata using (meta_data_key)
join d_unit_of_measure using (uom_key)
join b_procedure using (procedure_group_key)
join fd_procedure using (procedure_key)
where procedure_role='Result'  -- to expand later
	and level1_context_name='SCC'
	and level2_event_name='Lab Test'
	and level3_action_name ~ '(Other|Final|Preliminary|Corrected) Result'
	and level4_field_name ~ 'Clinical Result (Numeric|String)'
;
drop table if exists ct_scd._epic_lab;
create table ct_scd._epic_lab as
select distinct mrn, (age_in_days_key::float)::int as age_in_days
, test_name
, test_code::text test_code
, lab_status
, result_status
, test_result_value
, unit_of_measurement as unit_of_measure
from ct_scd.demo 
join epic_lab using(mrn)
;
-- select 345.85::int;
/*
select distinct procedure_type, procedure_description, source_name, active_flag, context_procedure_code, context_name
from fd_procedure
where lower(procedure_description) ~ 'a1c'
	and procedure_type = 'Lab Test'
;
*/

create temporary table _all_lab AS
select *, 'scc_lab' as source_table
from ct_scd._scc_lab
UNION
select *, 'epic_lab' as source_table
from ct_scd._epic_lab
;

-- deduplicate
drop table if exists ct_scd.lab;
create table ct_scd.lab as
select *
from (select *, row_number() over(
		partition by mrn, age_in_days, test_name, test_result_value,unit_of_measure
		order by source_table, test_code, lab_status, result_status)
	from _all_lab)
where row_number=1
	and test_result_value is not null
;

select count(*) from _all_lab; --12625265
select count(*) from ct_scd.lab; --7227918


/***
 * rx
 */
set search_path=dmsdw_2019q1;
set search_path=prod_msdw;
-- current medication filtering
--create temporary table _ori as
select * from d_metadata where
meta_data_key in (3810,3811,3814
	,4814,4819,4826,4781,4788
	,4802,4803,4804,4805,4809
	,5100,5115,5130,5145
	,5656,5655,5653,5649,5642,5643,5645
	,2573,2574
	,2039,2040,2041,2042)
or lower(level2_event_name) ~ '^medication (order|report)'
order by level2_event_name, level3_action_name, level4_field_name;
select * from _ori;
with curr as (
	select * from d_metadata 
	where level2_event_name='Medication Administration'
			and (level3_action_name='Given' and level4_field_name !~ 'Comments|Entered By| ID|[dny] Date' -- not due date
				-- Dose, Administered (Note|Unit|Status), Bolus Drug, Infusion (Drug|Rate), (Medication )?Route( Detail)?, Site, Reason, Due Date, Repeat Patttern and Duration
				or level3_action_name in ('Acknowledged', 'Held', 'Ordered') and level4_field_name='Dose')
		or level2_event_name='Prescription'
			and (level4_field_name='SIG' and level3_action_name not in ('Suspend', 'Canceled')
				-- Written, Verified, Pending Verify, Dispensed, Completed, Discontinued, Others
				or level4_field_name='Dose' and level3_action_name='Written')
)
select * from _ori
except
select * from curr
;

drop table if exists ct_scd._rx;
create table ct_scd._rx as
select distinct mrn, age_in_days_key as age_in_days
, level1_context_name as source
, level2_event_name as rx_event
, level3_action_name as rx_action
, level4_field_name as rx_detail
, value
, material_name as rx_name
, generic_name as rx_generic
, material_type
, context_material_code
, context_name
from (ct_scd.demo join d_person on mrn=medical_record_number)
join fact using (person_key)
join d_metadata using (meta_data_key)
join b_material using (material_group_key)
join fd_material using (material_key)
where level2_event_name='Medication Administration'
		and (level3_action_name='Given' and level4_field_name !~ 'Comments|Entered By| ID| [dny] Date' -- not due date
			-- Dose, Administered (Note|Unit|Status), Bolus Drug, Infusion (Drug|Rate), (Medication )?Route( Detail)?, Site, Reason, Due Date, Repeat Patttern and Duration
			or level3_action_name in ('Acknowledged', 'Held', 'Ordered') and level4_field_name='Dose')
	or level2_event_name='Prescription'
		and (level4_field_name='SIG' and level3_action_name not in ('Suspend', 'Canceled')
			-- Written, Verified, Pending Verify, Dispensed, Completed, Discontinued, Others
			or level4_field_name='Dose' and level3_action_name='Written')
;


--select count(distinct mrn) from tmp
select * from ct_scd._rx
where mrn in (select distinct mrn from tmp)
order by mrn, age_in_days, rx_event, rx_action, rx_name, rx_detail
;
select source, rx_event, rx_action, rx_detail, material_type
, count(*) records, count(distinct mrn) patients, count(distinct rx_name) meds, count(distinct rx_generic) drugs
from ct_scd._rx
group by source, rx_event, rx_action, rx_detail, material_type
;
-- Administered_status not useful 'Given'
-- Due Date not useful
-- Administered Unit and Route better to pivot columns
-- COMPURECORD, SIGNOUT?? scott
-- TDS material type Not available??
-- Site??  scott
-- action - IBEX only: Held=6, ordered=27, Acknowledged_Dose=53, Given_Repeat Pattern=105

drop table if exists ct_scd.rx;
create table ct_scd.rx AS
select mrn, age_in_days, rx_name, rx_generic
, listagg(distinct source, ' |') sources
, listagg(distinct rx_event, ' |') rx_events
, listagg(distinct rx_action, ' |') rx_actions
, listagg(distinct rx_detail, ' |') within group (order by rx_detail) rx_details
from ct_scd._rx
group by mrn, age_in_days, rx_name, rx_generic
;

select * from ct_scd.rx
order by mrn, age_in_days, rx_name, rx_generic
;

create table ct_scd.rx_list as
select rx_name, rx_generic
, count(*) rx_days, count(distinct mrn) patients
from ct_scd.rx
group by rx_name, rx_generic
order by patients desc, rx_days desc
;


/*********
 * explore
 */
select * from _kinds_of_procedures
where lower(procedure_description) ~
--'transfusion'
'stem cell'
--'pluripotent'
;

create table _kinds_of_rx_ as
select rx_name, rx_generic, context_material_code, context_name, count(*) records
from _rx
group by rx_name, rx_generic, context_material_code, context_name
; -- code is not helpfule
select * from _kinds_of_rx_ order by rx_name, rx_generic, context_name, context_material_code;

create table _kinds_of_rx as
select rx_name, rx_generic, count(*) records
from rx
group by rx_name, rx_generic
;
select * from _kinds_of_rx
where lower(rx_name || '; ' || rx_generic) ~
'hydroxy'
;
select * from dx
where lower(description) ~ 'alcohol abuse'
;

drop table _kinds_of_icds;
create table _kinds_of_icds as
select context_name, context_diagnosis_code, description
, count(*) records
from dx
where description != 'NOT AVAILABLE'
group by context_name, context_diagnosis_code, description
;
grant all on schema ct_scd to wen_pan;
select * from dmsdw_2019q1.d_person limit 10;