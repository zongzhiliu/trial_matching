/***
Requires:
    prod_msdw...
    cohort
Results:
    @set cancer_type=
    @set cancer_type_icd=
Settings
*/
--set search_path=ct_${cancer_type};

drop table if exists _pool_by_encounter cascade;
create temporary table _pool_by_encounter as
with _cohort_encounter as (
    select mrn, encounter_key
    , begin_date_time encounter_begin, encounter_type
    from cohort
    join prod_references.person_mrns pm using (person_id)
    join prod_msdw.d_encounter de on de.medical_record_number=pm.mrn
    where encounter_key>3
), _icd_enc as (
    select distinct encounter_key
    from _cohort_encounter
    join prod_msdw.fact f using (encounter_key)
    join prod_msdw.b_diagnosis bd using (diagnosis_group_key)
    join prod_msdw.v_diagnosis_control_ref vd using (diagnosis_key)
    where vd.context_name like 'ICD-%' and context_diagnosis_code ~ '${cancer_type_icd}'
), _cc_enc as (
    select distinct caregiver_control_key, encounter_key
    from _cohort_encounter
    join prod_msdw.fact f using (encounter_key)
    join prod_msdw.b_caregiver bc using (caregiver_group_key)
    join prod_msdw.v_caregiver_control_ref vc using (caregiver_key)
    join ct.caregiver_zip using (caregiver_control_key)
    where caregiver_control_key>3
    --  bc.caregiver_role in ('Primary', 'attending')
)
select distinct mrn, caregiver_control_key, encounter_key
, encounter_begin
from _cohort_encounter ce
join _icd_enc using (encounter_key)
join _cc_enc using (encounter_key)
;
/*
select count(distinct mrn), count(distinct caregiver_control_key), count(*) from ct._pool_by_encounter;
 -- by same encounter: 3185 |   19815| 408528
 total patients 3224 why missing? we require that icd are mapped with caregiver within the same encounter
*/
drop view if exists _pool;
create or replace view _pool as
select *, encounter_begin calendar_date
from _pool_by_encounter
;
-- prepare the prioritizing criteria
drop table if exists _freqs;
create table _freqs as
with _freq_3_y as (
    select mrn, caregiver_control_key
    , count(*) as freq_3_y
    from _pool
    where datediff(day, calendar_date, '${protocal_date}')/365.25 <= 3
    group by mrn, caregiver_control_key
),  _freq_1_y as (
    select mrn, caregiver_control_key
    , count(*) as freq_1_y
    from _pool
    where datediff(day, calendar_date, '${protocal_date}')/365.25 <= 1
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
select count(distinct mrn) from ct._freqs ;
--3185
*/

-- pick only ONE oncologist for each patient
drop table if exists _person_caregiver cascade;
create table _person_caregiver as
with res as (
    select person_id, caregiver_control_key, first_name, last_name
    , known_zip, known_job_title, cz.status, cz.source_name
    , cz.known_specialty
    , specialty_rank, freq_3_y, freq_1_y, last_visit
    from _freqs
    join prod_references.person_mrns using (mrn)
    join ct.caregiver_zip cz using (caregiver_control_key)
    join ct.caregiver_specialty_rank using (caregiver_control_key)
)
select *
from (select *, row_number() over(
        partition by person_id
        order by specialty_rank, -freq_3_y, -freq_1_y, last_visit desc nulls last, known_zip)
    from res)
where row_number=1
;
/*
select count (distinct person_id), count(distinct caregiver_control_key) from ct._person_caregiver;
    --  3178 |   338
*/

drop view if exists v_person_caregiver;
create view v_person_caregiver as
select pc.*, cnz.known_zip known_zip_extended
from cohort
left join _person_caregiver pc using (person_id)
join ct.caregiver_name_zip cnz using (first_name, last_name)
order by caregiver_control_key is null, known_zip_extended
;
/*
select (known_zip_extended is not null) has_zip, count(distinct person_id)
from v_person_caregiver
group by has_zip
;
select (known_zip_extended is not null) has_zip, count(distinct first_name || last_name)
from v_person_caregiver
group by has_zip
;
*/

drop view if exists v_treating_physician;
create view v_treating_physician as
select person_id+3040 person_id
, caregiver_control_key, cnz.known_zip caregiver_zip
from cohort
left join _person_caregiver pc using (person_id)
left join ct.caregiver_name_zip cnz using (first_name, last_name)
order by caregiver_control_key is null, cnz.known_zip is null
;

/* deprecated
create table ct._pool_by_visit as
with _encounter as (
	select medical_record_number mrn
	, encounter_key, encounter_visit_id
	, begin_date_time::date encounter_begin
	from d_encounter
	where encounter_visit_id is not NULL and encounter_key>3
), _cohort_encounter as (
    select mrn, encounter_visit_id
    , min(encounter_begin) encounter_begin
    from ct_nsclc.cohort
    join prod_references.person_mrns pm using (person_id)
    join _encounter de using (mrn) --on pm.mrn=de.medical_record_number
    --where encounter_visit_id is not null
    group by mrn, encounter_visit_id
), _icd_enc as (
    select distinct  encounter_visit_id
    from _cohort_encounter
    join _encounter de using (encounter_visit_id)
    join fact f using (encounter_key)
    join b_diagnosis bd using (diagnosis_group_key)
    join v_diagnosis_control_ref vd using (diagnosis_key)
    where vd.context_name like 'ICD-%' and context_diagnosis_code ~ '^(C34|162)' -- LCA
), _cc_enc as (
    select distinct caregiver_control_key, encounter_visit_id
    -- caregiver_role
    from _cohort_encounter
    join _encounter de using (encounter_visit_id)
    join fact f using (encounter_key)
    join b_caregiver bc using (caregiver_group_key)
    join v_caregiver_control_ref vc using (caregiver_key)
    join ct.caregiver_zip using (caregiver_control_key)
    --where --known_specialty ~ 'Oncology' 
    --    bc.caregiver_role in ('Primary', 'attending')
)
select distinct mrn, caregiver_control_key, encounter_visit_id
, encounter_begin
from _cohort_encounter ce
join _icd_enc using (encounter_visit_id)
join _cc_enc using (encounter_visit_id)
;
select count(distinct mrn), count(distinct caregiver_control_key), count(*) from ct._pool_by_visit;
--  3185 | 26014 | 539622 -- no improvement vs by_encounter
*/

/* old
create table _pool_by_fact as
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
-- and known_specialty ~ 'Oncology'
;
select count(distinct mrn), count(distinct caregiver_control_key), count(*) from _pool;
 --1042 |    71 | 25693  only 1/3 patients has an oncologist assigned
*/

