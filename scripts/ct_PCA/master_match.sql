/***
Requires:
    _p_a_...
    _p_a_t_...
    trial_attribute_used
Results:
    _master_match
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
    --22 unimplemented
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

