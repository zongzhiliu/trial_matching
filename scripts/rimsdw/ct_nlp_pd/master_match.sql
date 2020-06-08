/***
Requires: cohort
    _p_a_...
Results:
    master_match
*/
-- default match to false for medications and icds
create temporary table _match_p_a_default_false as
with pa as (
    select attribute_id, person_id, NULL::varchar as patient_value, match from _p_a_drug
    union select attribute_id, person_id, NULL, match from _p_a_icd_rex
), a_all as (
    select distinct attribute_id from crit_attribute_used where code_type ~ '^(drug_|icd_)' --quickfix
)
select attribute_id, person_id, patient_value
, nvl(match, False) as match
from (cohort cross join a_all)
left join pa using (person_id, attribute_id)
;

drop table if exists _match_p_a cascade;
create table _match_p_a as
select attribute_id, person_id, patient_value::varchar, match from _match_p_a_default_false
union select attribute_id, person_id, patient_value::varchar, match from _p_a_stage
--union select attribute_id, person_id, patient_value::varchar, match from _p_a_histology
union select attribute_id, person_id, NULL, match from _p_a_variant --mutation
union select attribute_id, person_id, NULL, match from _p_a_biomarker
union select attribute_id, person_id, NULL, match from _p_a_loinc
union select attribute_id, person_id, NULL, match from _p_a_query_lab
union select attribute_id, person_id, NULL, match from _p_a_numeric_measurement
union select attribute_id, person_id, NULL, match from _p_a_mm_active_status
union select attribute_id, person_id, NULL, match from _p_a_mm_cancer_dx
union select attribute_id, person_id, NULL, match from _p_a_translocation
;

select count(distinct attribute_id) from _match_p_a ;

create or replace view qc_missing_crit as 
select *
from crit_attribute_used
where attribute_id not in (select distinct attribute_id from _match_p_a order by attribute_id)
Order By attribute_id;
select * from qc_missing_crit;

/*
create view _qc_match_pa as
with tmp as (
    select attribute_id, attribute_name, attribute_value, match
    , case when match then count(distinct person_id) else 0 end patients
    from crit_attribute_used
    left join _match_p_a using (attribute_id)
    group by attribute_id, attribute_name, attribute_value, match
)
select  attribute_id, attribute_name, attribute_value
, max(patients) matched_patients
from tmp
group by  attribute_id, attribute_name, attribute_value
order by attribute_id
;
*/

-- set match as null by default for each patient
create or replace view _master_match as select * from _match_p_a;

drop table if exists master_match cascade;
create table master_match as
select attribute_id, person_id
, bool_or(match) as attribute_match --quick fix: multiple matches
from (cohort cross join crit_attribute_used)
left join _master_match using (person_id, attribute_id)
group by attribute_id, person_id
;

create or replace view qc_master_match as
with tmp as (
    select attribute_id, attribute_name, attribute_value, attribute_match
    , count(*) records, count(distinct person_id) patients
    from master_match
    join crit_attribute_used using (attribute_id)
    group by attribute_id, attribute_name, attribute_value, attribute_match
)
select  attribute_id, attribute_name, attribute_value
, max(case when attribute_match is True then patients else 0 end) patients_True
, max(case when attribute_match is False then patients else 0 end) patients_False
, max(case when attribute_match is Null then patients else 0 end) patients_Null
from tmp
group by  attribute_id, attribute_name, attribute_value
order by attribute_id
;

drop table if exists "_qc_master_match_used" cascade;
create table _qc_master_match_used as
with au as (
	select distinct attribute_id, code_type 
	from trial_attribute_used join crit_attribute_used using (attribute_id)
)
select *
from qc_master_match 
join au using (attribute_id)
order by attribute_id
;
create or replace view qc_master_match_used as
select * from _qc_master_match_used order by attribute_id;

select * from qc_master_match_used;


