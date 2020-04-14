/***
Requires:
    _p_a_...
    _p_a_t_...
    trial_attribute_used
Results:
    master_match
*/

drop table if exists _p_a_t_match cascade;
create table _p_a_t_match as
select attribute_id, trial_id, person_id, patient_value::varchar, match from _p_a_t_age
union all select attribute_id, trial_id, person_id, patient_value::varchar, match from _p_a_t_weight
union all select attribute_id, trial_id, person_id, patient_value::varchar, match from _p_a_t_lab
union all select attribute_id, trial_id, person_id, patient_value::varchar, match from _p_a_t_blood_pressure
union all select attribute_id, trial_id, person_id, patient_value::varchar, match from _p_a_t_gleason
union all select attribute_id, trial_id, person_id, patient_value::varchar, match from _p_a_t_psa_at_diagnosis
;
/*
select distinct(attribute_id) from _p_a_t_match;
--14
*/

-- disabled for now -- quickfix
-- default match to false for medications and icds
drop table if exists _p_a_default_false;
create temporary table _p_a_default_false as
with pa as (
    select attribute_id, person_id, patient_value::varchar, match from _p_a_chemotherapy
    union select attribute_id, person_id, patient_value::varchar, match from _p_a_hormone_therapy
    union select attribute_id, person_id, patient_value::varchar, match from _p_a_immunotherapy
    union select attribute_id, person_id, patient_value::varchar, match from _p_a_targetedtherapy
    union select attribute_id, person_id, patient_value::varchar, match from _p_a_disease
    union select attribute_id, person_id, patient_value::varchar, match from _p_a_disease_status
), a_all as (
    select distinct attribute_id from pa
)
select attribute_id, person_id, patient_value
, nvl(match, False) as match
--, match
from (cohort cross join a_all)
left join pa using (person_id, attribute_id)
;
/*
select distinct(attribute_id) from _p_a_default_false;
    --49
select match, count(*) from _p_a_default_false group by match;
*/
drop table if exists _p_a_match cascade;
create table _p_a_match as
select attribute_id, person_id, patient_value::varchar, match from _p_a_stage
union select attribute_id, person_id, patient_value::varchar, match from _p_a_lab
union select attribute_id, person_id, patient_value::varchar, match from _p_a_lot
union select attribute_id, person_id, patient_value::varchar, match from _p_a_ecog
union select attribute_id, person_id, patient_value::varchar, match from _p_a_karnofsky
--union select attribute_id, person_id, patient_value::varchar, match from _p_a_mutation
union select attribute_id, person_id, patient_value::varchar, match from _p_a_histology
union select attribute_id, person_id, patient_value::varchar, match from _p_a_default_false
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
with mm as (
    select attribute_id, trial_id, person_id, patient_value::varchar, match
    from _p_a_t_match
    union all
    select attribute_id, trial_id, person_id, patient_value::varchar, match
    from _p_a_match join trial_attribute_used using (attribute_id)
)
-- quickfix: remove attributes with only null matches
, a_good as (
    select attribute_id
    , bool_or(match is not null) good
    from mm
    group by attribute_id
    having (good)
)
select mm.*
from mm join a_good using (attribute_id)
;
------------------------------------------------------------
-- qc
select count(*), count(distinct attribute_id) from _master_match;
    -- 36248441 |   148
with unimpl as (
    select distinct attribute_id from trial_attribute_used except
    select distinct attribute_id from _master_match
)
select attribute_id, attribute_group, attribute_name, attribute_value
from unimpl join crit_attribute_used using (attribute_id)
;
    --24 unimplemented
/*
select * from _master_match
order by person_id, trial_id, attribute_id
limit 100;
with total as (
select count(*) from _master_match
), uniq as (
select count(*) from (select distinct * from _master_match)
), pat as (
select count(*) from (select distinct person_id, trial_id, attribute_id from _master_match)
)
select * from total union all
select * from uniq union all
select * from pat
;

*/
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

