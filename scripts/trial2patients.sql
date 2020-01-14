SET search_path=ct_nsclc;
/***
 * trial and attributes
 */
-- trial_attribute_used from raw
drop table if exists trial_attribute_used cascade;
create table trial_attribute_used as
select  nct_id as trial_id
, attribute_id, inclusion, exclusion
from trial_attribute_raw_20200106
where nvl(inclusion, exclusion) is not null
order by trial_id, attribute_id
;

-- attribute_used
drop table if exists attribute_used cascade;
create table attribute_used as
select attribute_id, count(*) trials
from trial_attribute_used
group by attribute_id
order by trials desc
;

-- crit_attribute_used from raw and attibute_used
drop table if exists crit_attribute_used cascade;
create table crit_attribute_used as
select crit_id
, crit_name, must_have_data_for_matching
, attribute_id
, attribute_group, attribute_name, value
, trials
from crit_attribute_20200106
join attribute_used using (attribute_id)
;

--crit_used
drop table if exists crit_used cascade;
create table crit_used as
select crit_id, crit_name, must_have_data_for_matching
, count(distinct trial_id) as trials
from crit_attribute_used
join trial_attribute_used using (attribute_id)
group by crit_id, crit_name, must_have_data_for_matching
;

-- report as views
create or replace view v_crit_attribute_used as
select * from crit_attribute_used order by attribute_id;
create or replace view v_crit_used as
select * from crit_used order by crit_id;

create or replace view v_trial_using_crits as
select trial_id
, count(distinct crit_id) crits
, count(distinct attribute_id) attributes
from trial_attribute_used
join crit_attribute_used using (attribute_id)
group by trial_id
order by crits desc, attributes desc
;


/*qc
select count(*) from trial_attribute_used; --3482
select count(*) from attribute_used; --135
select count(*) from crit_attribute_used; --135 good
select count(*) from crit_used; --80
 */

/***
 * patient attribute from v_p_a_combined
 */
-- patient attribute
drop table if exists patient_attribute cascade;
create table patient_attribute as
select person_id, attribute_id, attribute_match, patient_value
from ct_lca.v_p_a_combined
join attribute_used using (attribute_id)
join cohort using (person_id)
;
--report to mask the person_id
create or replace view v_patient_attribute as
select person_id+3040 person_id, attribute_id, attribute_match, patient_value 
from patient_attribute
order by person_id, attribute_id
;


/***
 * master_sheet
 */
create or replace view master_sheet as
select trial_id, person_id, attribute_id
, a.attribute_group, a.attribute_name, a.value
, inclusion, exclusion, attribute_match, patient_value
from crit_attribute_used a
join trial_attribute_used t using (attribute_id)
join patient_attribute p using (attribute_id)
order by trial_id, person_id, attribute_id
;
-- report to mask the person_id
drop view v_master_sheet;
create or replace view v_master_sheet as
select trial_id, person_id+3040 person_id
, attribute_id, attribute_name, value
, inclusion, exclusion
, attribute_match --, patient_value
from master_sheet 
;
-- select count(distinct trial_id), count(distinct attribute_id) from v_trial_attribute_used;
-- select count(distinct person_id),  count(distinct trial_id), count(distinct attribute_id) from v_master_sheet;
--select distinct trial_id from ct_nsclc.v_master_sheet -- where trial_id='NCT03347838';

-- report number of implemented and data extracted attributes for each trial
create or replace view v_trial_consolidated_crits as
select trial_id
, count(distinct crit_id) crits
, count(distinct attribute_id) attributes
from master_sheet
join crit_attribute_used using (attribute_id)
where attribute_match is not null
group by trial_id
order by crits desc, attributes desc
;
--select * from v_trial_consolidated_crits;
create view v_trial_crits_summary as
select trial_id
, u.crits using_crits
, u.attributes using_attrs
, c.crits consolidated_crits
, c.attributes consolidated_attrs
from v_trial_using_crits u
join v_trial_consolidated_crits c using (trial_id)
order by consolidated_crits desc, using_crits
;
--drop view v_trial_criteria;
create view v_trial_crits_summary_with_criteria as
select c.*
, gender, minimum_age, maximum_age
, population
, criteria
from v_trial_crits_summary c
join ctgov.eligibilities on trial_id=nct_id
;




/***
 * master crit match
 */
drop table trial_crit_used cascade;
create table trial_crit_used as
with tmp as (
	select trial_id, crit_id
	, bool_or(inclusion is not null) as inclusive
	, bool_or(exclusion is not null) as exclusive
	from trial_attribute_used
	join crit_attribute_used using (attribute_id)
	group by trial_id, crit_id
	order by trial_id, crit_id
)
/* qc
--select inclusive, exclusive, count(distinct crit_id) from tmp group by inclusive, exclusive
select trial_id, crit_id, attribute_id
, attribute_group, attribute_name, value, inclusion, exclusion
from tmp 
join crit_attribute_used using (crit_id)
join trial_attribute_used using (trial_id, attribute_id) 
where inclusive=exclusive
order by trial_id, attribute_id
*/
select trial_id, crit_id, inclusive
, case when inclusive then false else exclusive end as exclusive 
from tmp
;


--select distinct inclusive, exclusive from trial_crit_used;
create view trial_crit_used_summary as
select trial_id
, sum(inclusive::int) trial_inclusions
, sum(exclusive::int) trial_exclusions
from trial_crit_used
group by trial_id
;

/*
drop view "_crit_attribute_match";
create or replace view _crit_attribute_match as
select trial_id, person_id
, crit_id, crit_name
, inclusive as crit_inclusive, exclusive as crit_exclusive
, attribute_id
--, a.attribute_group, a.attribute_name
, a.value
, inclusion, exclusion, attribute_match--, patient_value
from crit_attribute_used a
join trial_attribute_used t using (attribute_id)
join patient_attribute p using (attribute_id)
-- remove rows with crit_inclusive and attr_exclusion
where crit_inclusive and inclusion is not null
	or crit_exclusive and exclusion is not null
order by trial_id, person_id, attribute_id
;
select count(*) from _crit_attribute_match; --6737660
select count(*) from master_sheet where nvl(inclusion, exclusion) is not null; --6737660
select count(*) from master_sheet join crit_attribute_used using (attribute_id) join trial_crit_used using (trial_id, crit_id);
*/
create table _master_sheet_with_crit as
select trial_id, person_id
, attribute_id, inclusion attr_inclusion, exclusion attr_exclusion
, attribute_match
, crit_id, inclusive crit_inclusive, exclusive crit_exclusive
from master_sheet
join crit_attribute_used using (attribute_id)
join trial_crit_used using (trial_id, crit_id)
where crit_inclusive and attr_inclusion is not null
	or crit_exclusive and attr_exclusion is not null
;

-- select count(*) from _master_sheet_with_crit;  --6717901
drop table crit_pass cascade;
create table crit_pass as
select trial_id, person_id, crit_id
, crit_inclusive, crit_exclusive
, bool_or(attribute_match) crit_match
, case when crit_inclusive then crit_match
	when crit_exclusive then not crit_match 
    end as crit_pass
from _master_sheet_with_crit
group by trial_id, person_id, crit_id, crit_inclusive, crit_exclusive
;
-- select * from crit_pass order by trial_id, person_id, crit_id;

create view crit_pass_no_nulls as
select cp.*
, nvl(crit_pass, true) as crit_pass_aggressive
, nvl(crit_pass, false) as crit_pass_conservative
, case must_have_data_for_matching 
	when 'yes' then crit_pass_conservative
	when 'no' then crit_pass_aggressive
	end crit_pass_balanced
from crit_pass cp
join crit_used using (crit_id)
;
/*
select crit_pass_aggressive, crit_pass_conservative, crit_pass_balanced, count(*)
from crit_pass_no_nulls
group by crit_pass_aggressive, crit_pass_conservative, crit_pass_balanced
;*/
select * from crit_pass_no_nulls;
drop table crit_pass_summary cascade;
create table crit_pass_summary as
select trial_id, person_id, trial_inclusions, trial_exclusions
, bool_and(crit_pass) as all_passed_aggressive
, bool_and(nvl(crit_pass, False)) as all_passed_conservative
, bool_and(case must_have_data_for_matching 
	when 'yes' then nvl(crit_pass, False)
	when 'no' then nvl(crit_pass, False)
	end) all_passed_balanced
, sum((crit_inclusive and crit_match is not null)::int) inclusive_extracted
, sum((crit_inclusive and nvl(crit_match, false))::int) inclusive_passes
, sum((crit_exclusive and crit_match is not null)::int) exclusive_extracted
, sum((crit_exclusive and nvl(not crit_match, false))::int) exclusive_passes
from crit_pass
join trial_crit_used_summary using (trial_id)
join crit_used using (crit_id)
group by trial_id, person_id, trial_inclusions, trial_exclusions
;
--select * from crit_pass_summary;
select all_passed_aggressive, all_passed_conservative, all_passed_balanced, count(*)
from crit_pass_summary
group by all_passed_aggressive, all_passed_conservative, all_passed_balanced
;
--select crit_id, must_have_data_for_matching from crit_attribute_used group by crit_id, must_have_data_for_matching

--show search_path;
--drop view trial2patients;
create or replace view trial2patients as
	select trial_id
	, sum(all_passed_aggressive::int) patients_passed_aggressive
	, sum(all_passed_conservative::int) patients_passed_conservative
	from crit_pass_summary
	group by trial_id
	order by patients_passed_aggressive desc, patients_passed_conservative desc
;
select distinct must_have_data_for_matching from crit_attribute_used;




------
drop view patient2trials;
create or replace view patient2trials as
	select person_id, sum(all_passed::int) trials
	from crit_pass_summary
	group by person_id
	order by trials desc
;


create view mount_sinai_crit_pass_summary as
	select facility as mount_sinai_facility
	, cps.*
	from crit_pass_summary cps
	left join (
		select nct_id as trial_id, facility 
		from ctgov.v_mount_sinai_nsclc_trials) ms using (trial_id)
	order by person_id, mount_sinai_facility, trial_id
;

create or replace view mount_sinai_trials_passed as
	select * from mount_sinai_crit_pass_summary
	where all_passed and mount_sinai_facility is not null
;

/**