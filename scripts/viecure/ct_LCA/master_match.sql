/***
Requires: cohort, trial_attribute_used
    _p_a_...
    _p_a_t_...
Results:
    master_match
*/

drop table if exists _match_p_a_t cascade;
create table _match_p_a_t as
select attribute_id, trial_id, person_id, patient_value::varchar, match from _p_a_t_age union
select attribute_id, trial_id, person_id, NULL, match from _p_a_t_stage
;

-- default match to false for medications and icds
create temporary table _match_p_a_default_false as
with pa as (
    select attribute_id, person_id, NULL::varchar as patient_value, match from _p_a_drug_improved
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
-- union select attribute_id, person_id, patient_value::varchar, match from _p_a_histology
union select attribute_id, person_id, NULL, match from _p_a_variant --mutation
union select attribute_id, person_id, NULL, match from _p_a_biomarker
-- union select attribute_id, person_id, patient_value::varchar, match from _p_a_lot
union select attribute_id, person_id, patient_value::varchar, match from _p_a_test
union select attribute_id, person_id, NULL, match from _p_a_performance
;
/*
select distinct(attribute_id) from _p_a_match;
    --137
select attribute_id, attribute_name, attribute_value
, match, count(*)
from _p_a_match
join crit_attribute_used using (attribute_id)
group by attribute_id, attribute_name, attribute_value, match
order by attribute_id, match
;
*/

-- compile all the implemented matches
drop view if exists _master_match cascade;
create view _master_match as
    select attribute_id, trial_id, person_id, patient_value::varchar, match
    from _match_p_a_t
    union all
    select attribute_id, trial_id, person_id, patient_value::varchar, match
    from _match_p_a join trial_attribute_used using (attribute_id)
;
------------------------------------------------------------
-- qc
-- select count(*), count(distinct attribute_id) from _master_match;

-- set match as null by default for each patient
drop table if exists master_match cascade;
create table master_match as
with a_good as (
    select distinct attribute_id from _master_match
), ta_good as (
    select * from trial_attribute_used
    join a_good using (attribute_id)
)
select attribute_id, trial_id, person_id
, bool_or(match) as attribute_match --quick fix: multiple matches
from (ta_good cross join cohort)
left join _master_match using (attribute_id, trial_id, person_id)
group by attribute_id, trial_id, person_id
;

-- assert: each trial have same number of attributes for all patients
with tpc as (
    select trial_id, person_id, count(attribute_id)
    from master_match
    group by trial_id, person_id
), tc as (
    select distinct trial_id, count
    from tpc
)
select ct.assert(count(distinct trial_id) = count(*)
    , 'each trial have same number of attributes for all patients')
from tc
;

create or replace view qc_attribute_match_summary as
with cp as (
    select attribute_id, attribute_match
    , count(distinct person_id) patients
    from master_match
    group by attribute_id, attribute_match
), cp_pivot as (
    select attribute_id
    , nvl(sum(case when attribute_match is True then patients end), 0) patients_true
    , nvl(sum(case when attribute_match is False then patients end), 0) patients_false
    , nvl(sum(case when attribute_match is Null then patients end), 0) patients_null
    from cp group by attribute_id
), ct as (
    select attribute_id, ie_flag inclusion
    , count(distinct trial_id) trials
    from trial_attribute_used
    group by attribute_id, inclusion
), ct_pivot as (
	select attribute_id
    , nvl(sum(case when inclusion then trials end), 0) trials_inc
    , nvl(sum(case when not inclusion then trials end), 0) trials_exc
    from ct group by attribute_id
)
select attribute_id
, trials_inc, trials_exc
, patients_true, patients_false, patients_null
, attribute_group+'| '+attribute_name+'| '+attribute_value as attribute_title
from ct_pivot join cp_pivot using (attribute_id) 
join crit_attribute_used using (attribute_id)
order by attribute_id
;
select * from qc_attribute_match_summary;
