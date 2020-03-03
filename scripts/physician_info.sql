/***
* collect physician info from the d_caregiver table, and map them to a patient
*/
-- collect info from d_caregiver
set search_path=prod_msdw;
drop table if exists tmp;
create temporary table tmp as
    select distinct caregiver_key, caregiver_control_key, first_name, last_name
    , status, active_flag, date_activated::date, date_of_birth::date
    , case when zip not in ('NOT AVAILABLE', '0') then 
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
;
create table ct.caregiver as (
select caregiver_key, caregiver_control_key, first_name, last_name 
, date_of_birth, date_activated, known_zip
, known_specialty, known_department
from tmp 
where known_job_title='MD' 
and active_flag='Y'
and status='Active' --caregiver_type all Practitioner
order by caregiver_control_key, caregiver_key
)
;

-- try to rescue the unknown zip code for a caregiver
create table ct.caregiver_zip_rescued as
with pool as (
    select caregiver_key, caregiver_control_key, known_zip
    from (select caregiver_control_key from ct.caregiver where known_zip is null)
    join tmp using (caregiver_control_key)
    where known_zip is not null
)
select *
from (select *, row_number() over (
        partition by caregiver_control_key
        order by caregiver_key)
    from pool)
where row_number=1
;
    -- only 57 can be recovered
create table ct.caregiver_zip as
select caregiver_control_key, first_name, last_name
, known_specialty, date_activated, known_zip
from ct.caregiver;
update ct.caregiver_zip set known_zip=cr.known_zip
from ct.caregiver_zip_rescued cr
join ct.caregiver_zip cz using (caregiver_control_key)
;

-- map the NSCLC patients to relevant oncologists
drop table ct._pool;
create table ct._pool_by_encounter_key as
with _cohort_encounter as (
    select mrn, encounter_key, encounter_visit_id
    , begin_date_time encounter_begin, encounter_type
    from ct_nsclc.cohort
    join prod_references.person_mrns pm using (person_id)
    join d_encounter de on de.medical_record_number=pm.mrn
), _icd_enc as (
    select distinct encounter_key, encounter_visit_id
    from _cohort_encounter
    join fact f using (encounter_key)
    join b_diagnosis bd using (diagnosis_group_key)
    join v_diagnosis_control_ref vd using (diagnosis_key)
    where vd.context_name like 'ICD-%' and context_diagnosis_code ~ '^(C34|162)' -- LCA
), _onco_enc as (
    select distinct caregiver_control_key, encounter_key, encounter_visit_id
    from _cohort_encounter
    join fact f using (encounter_key)
    join b_caregiver bc using (caregiver_group_key)
    join v_caregiver_control_ref vc using (caregiver_key)
    join ct.caregiver_zip using (caregiver_control_key)
    where known_specialty ~ 'Oncology'
)
select distinct mrn, caregiver_control_key, encounter_visit_id
, ce.encounter_key
, encounter_begin
from _cohort_encounter ce
join _icd_enc using (encounter_visit_id)
join _onco_enc using (encounter_visit_id)
;
/*
select count(distinct mrn), count(distinct caregiver_control_key), count(*) from ct._pool;
 -- by same encounter_visit_id  1092 |    75 | 787224
 -- by same encounter: 1075 |    74 | 29195
 -- old by same fact: 1042 |    71 | 25693  only 1/3 patients has an oncologist assigned
*/

/* old
create table _pool as
select distinct mrn, caregiver_control_key, calendar_date
from ct_nsclc.cohort
join prod_references.person_mrns pm using (person_id)
join d_person dp on dp.medical_record_number=pm.mrn
join fact f using (person_key)
join d_calendar using (calendar_key)
--join d_encounter using (encounter_key)
join b_diagnosis bd using (diagnosis_group_key)
join v_diagnosis_control_ref vd using (diagnosis_key)
join b_caregiver bc using (caregiver_group_key)
join v_caregiver_control_ref vc using (caregiver_key)
join ct.caregiver_zip using (caregiver_control_key)
where vd.context_name like 'ICD-%' and context_diagnosis_code ~ '^(C34|162)' -- LCA
and known_specialty ~ 'Oncology'
;
select count(distinct mrn), count(distinct caregiver_control_key), count(*) from _pool;
 --1042 |    71 | 25693  only 1/3 patients has an oncologist assigned
*/


-- prepare the prioritizing criteria
create table ct._freqs as
with _freq_3_y as (
    select mrn, caregiver_control_key
    , count(*) as freq_3_y
    from _pool
    where datediff(day, calendar_date, current_date)/365.25 <= 3
    group by mrn, caregiver_control_key
),  _freq_1_y as (
    select mrn, caregiver_control_key
    , count(*) as freq_1_y
    from _pool
    where datediff(day, calendar_date, current_date)/365.25 <= 1
    group by mrn, caregiver_control_key
),  _last_visit as (
    select mrn, caregiver_control_key
    , max(calendar_date) as last_visit
    from _pool
    group by mrn, caregiver_control_key
)
-- select count (distinct mrn) from _freq_3_y --537
-- select count (distinct mrn) from _freq_1_y --287
-- select count (distinct mrn) from _last_visit --1042
select mrn, caregiver_control_key
, nvl(freq_3_y, 0) freq_3_y
, nvl(freq_1_y, 0) freq_1_y
, last_visit
from _last_visit
left join _freq_3_y using (mrn, caregiver_control_key)
left join _freq_1_y using (mrn, caregiver_control_key)
;
/*
select count(distinct mrn) from ct._freqs
;
--1042
*/

-- pick only ONE oncologist for each patient
drop table ct._person_oncologist cascade;
create table ct._person_oncologist as
with res as (
    select person_id, caregiver_control_key, first_name, last_name
    , known_zip , known_specialty
    , freq_3_y, freq_1_y, last_visit
    from ct._freqs
    join prod_references.person_mrns using (mrn)
    join ct.caregiver_zip using (caregiver_control_key)
)
select *
from (select *, row_number() over(
        partition by person_id
        order by -freq_3_y, -freq_1_y, last_visit desc nulls last, known_zip)
    from res)
where row_number=1
;
/*
select count (distinct person_id) from ct._person_oncologist;
*/

drop view ct.v_person_oncologist;
create view ct.v_person_oncologist as
select person_id, caregiver_control_key, first_name, last_name
, known_specialty, known_zip
, freq_3_y, freq_1_y, last_visit
from ct_nsclc.cohort
join ct._person_oncologist using (person_id)
order by known_zip
;
/*
select count (distinct person_id) from ct.v_person_oncologist;
*/
