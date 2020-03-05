/***
* collect physician info from the d_caregiver table, and map them to a patient
*/
-- collect info from d_caregiver
set search_path=prod_msdw;
drop table tmp;
create temporary table tmp as (
    select distinct caregiver_key, caregiver_control_key, first_name, last_name
    , status, active_flag, date_activated::date, date_of_birth::date, source_name
    , case when zip not in ('NOT AVAILABLE', '0', 'S', '<unknown>') then
        zip end as known_zip
    , case when caregiver_type not in ('NOT AVAILABLE', '<unknown>') then
        caregiver_type end as known_caregiver_type
    , case when job_title not in ('NOT AVAILABLE', '<unknown>') then
        job_title end as known_job_title
    , case when specialty not in ('NOT AVAILABLE', '<unknown>') then
        specialty end as known_specialty
    , case when department not in ('NOT AVAILABLE', '<unknown>') then
        department end as known_department
    from d_caregiver
);

drop table if exists ct._caregiver;
create table ct._caregiver as
select *
from tmp
where active_flag='Y'
order by caregiver_control_key, caregiver_key
--known_job_title='MD' 
--and status='Active' --caregiver_type all Practitioner
;

-- rescue the unknown zip code from other caregiver_keys
drop table ct._caregiver_zip_rescued;
create table ct._caregiver_zip_rescued as
with pool as (
    select caregiver_key, caregiver_control_key, known_zip
    from (select caregiver_control_key 
        from ct._caregiver where known_zip is null)
    join tmp using (caregiver_control_key)
    where known_zip is not null
)
select *
from (select *, row_number() over (
        partition by caregiver_control_key
        order by -caregiver_key)
    from pool)
where row_number=1  -- pick the zip with largest caregiver_key
;

drop table if exists ct.caregiver_zip cascade;
create table ct.caregiver_zip as
select caregiver_control_key, first_name, last_name
, known_specialty, known_zip
, date_activated, known_job_title, status, source_name
from ct._caregiver;

update ct.caregiver_zip set known_zip=cr.known_zip
from ct._caregiver_zip_rescued cr
join ct.caregiver_zip cz using (caregiver_control_key)
;

-- set specialty rank
/* physician list from tommy
create or replace view ct.v_no_filter_mapping as
select last_name, first_name
, caregiver_control_key
, known_specialty, known_zip
, date_activated, known_job_title, status, source_name
from ct.hema_onco_faculty ho
left join ct.caregiver_zip cz using (first_name, last_name)
order by caregiver_control_key is null, last_name, first_name
, source_name!='CACTUS', status!='Active', known_job_title!='MD'
;
*/

create table ct.caregiver_specialty_rank as
select caregiver_control_key, tmp, known_specialty
, case when from_tommy then 1
	when known_specialty ~ 'Oncology|Hematology' then 2
	when known_specialty is not null then 3
	end specialty_rank
from ct.caregiver_zip
left join (select *, True as from_tommy from ct.hema_onco_faculty) using (last_name, first_name)
order by specialty_rank
;

-- assign a zip code to each firstname + lastname
create table ct.caregiver_name_zip as
select last_name, first_name
, known_zip
from (select *, row_number() over (
        partition by last_name, first_name
        order by known_zip is null, status!='active', -caregiver_control_key)
    from ct.caregiver_zip)
where row_number=1
;
/*
select count(*) from ct.caregiver_name_zip
-- where known_zip is not null
;
select count(distinct last_name || first_name) from ct.caregiver_zip where known_zip is not null
;
*/
