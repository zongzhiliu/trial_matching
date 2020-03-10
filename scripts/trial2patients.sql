/***
Requires:
    trial_attributes_used, crit_attribute_used
    master_match
Results:
    v_master_sheet
    trial2patients
Settings:
    @set cancer_type=
    SET search_path=ct_${cancer_type};
*/
--crit_used
drop table if exists crit_used cascade;
create table crit_used as
select crit_id, crit_name, mandated
, count(distinct trial_id) as trials
from crit_attribute_used
join trial_attribute_used using (attribute_id)
group by crit_id, crit_name, mandated
;

-- report as views
create or replace view v_trial_using_crits as
select trial_id
, count(distinct crit_id) crits
, count(distinct attribute_id) attributes
from trial_attribute_used
join crit_attribute_used using (attribute_id)
group by trial_id
order by crits desc, attributes desc
;

-- report number of implemented and data extracted attributes for each trial
create or replace view v_trial_consolidated_crits as
select trial_id
, count(distinct crit_id) crits
, count(distinct attribute_id) attributes
from _master_sheet
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
/*
create view v_trial_crits_summary_with_criteria as
select c.*
, gender, minimum_age, maximum_age
, population
, criteria
from v_trial_crits_summary c
join ctgov.eligibilities on trial_id=nct_id
;
*/

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

drop table _master_sheet_with_crit;
create table _master_sheet_with_crit as
select trial_id, person_id
, attribute_id, inclusion attr_inclusion, exclusion attr_exclusion
, attribute_match
, crit_id, inclusive crit_inclusive, exclusive crit_exclusive
from _master_sheet
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
, case mandated
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
--select * from crit_pass_no_nulls;
drop table crit_pass_summary cascade;
create table crit_pass_summary as
select trial_id, person_id, trial_inclusions, trial_exclusions
, bool_and(crit_pass_aggressive) as all_passed_aggressive
, bool_and(crit_pass_conservative) as all_passed_conservative
, bool_and(crit_pass_balanced) as all_passed_balanced
, sum((crit_inclusive and crit_match is not null)::int) inclusive_extracted
, sum((crit_inclusive and nvl(crit_match, false))::int) inclusive_passes
, sum((crit_exclusive and crit_match is not null)::int) exclusive_extracted
, sum((crit_exclusive and nvl(not crit_match, false))::int) exclusive_passes
from crit_pass_no_nulls
join trial_crit_used_summary using (trial_id)
--join crit_used using (crit_id)
group by trial_id, person_id, trial_inclusions, trial_exclusions
;
/*
--select * from crit_pass_summary;
select all_passed_aggressive, all_passed_conservative, all_passed_balanced, count(*)
from crit_pass_summary
group by all_passed_aggressive, all_passed_conservative, all_passed_balanced
;
--select crit_id, mandated from crit_attribute_used group by crit_id, mandated
*/
--show search_path;
--drop view trial2patients;
create or replace view trial2patients as
    select trial_id
    , sum(all_passed_aggressive::int) patients_passed_aggressive
    , sum(all_passed_balanced::int) patients_passed_balanced
    , sum(all_passed_conservative::int) patients_passed_conservative
    from crit_pass_summary
    group by trial_id
    order by patients_passed_aggressive desc, patients_passed_balanced desc
;
/*qc
--select distinct mandated from crit_attribute_used;
select trial_id, person_id, attribute_id
attribute_inclusion, attr_exclusion, attribute_match
crit_id, crit_inclusive, crit_exclusive, crit_match, crit_pass
patients_passed_balanced
from _master_sheet_with_crit
join crit_pass_no_nulls using (crit_id, trial_id, person_id)
join crit_pass_summary using (trial_id, person_id)
join trial2patients using (trial_id)
where patients_passed_balanced > 300 and all_passed_balanced
order by trial_id, person_id, attribute_id
;
*/

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
