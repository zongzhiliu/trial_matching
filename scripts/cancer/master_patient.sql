/***
Requires:
    trial_attributes_used, crit_attribute_used
    _master_sheet
Results:
    trial_patient_match
Settings:
    @set cancer_type=
    SET search_path=ct_${cancer_type};
*/
-- match adjusted with i/e and mandatory
drop table if exists _match_adjusted cascade;
create table _match_adjusted as
select trial_id, person_id, attribute_id
, (inclusion is not null) as ie
, nvl(inclusion, exclusion) as ie_value
, (mandated='yes') as mandatory
, attribute_match
, nvl(attribute_match, not mandatory) as match_amputed
, case ie
    when True then match_amputed
    when False then not match_amputed
    end as match_adjusted
from _master_sheet
join crit_attribute_used using(attribute_id)
;
/*
select * from _match_adjusted
order by person_id, trial_id, attribute_id
limit 100;
*/
-- patient match with logic (or only)

drop table if exists trial_patient_match cascade;
create table trial_patient_match as
with _crit_match as (
    select trial_id, person_id
    , nvl(logic, attribute_id) as crit_id
    , bool_or(match_adjusted) crit_match
    from _match_adjusted
    join crit_attribute_used using (attribute_id)
    group by trial_id, person_id, crit_id
)
select trial_id, person_id
, bool_and(crit_match) patient_match
from _crit_match
group by trial_id, person_id
;

drop view if exists v_trial_patient_count;
create view v_trial_patient_count as
select trial_id
, sum(patient_match::int) patients
from trial_patient_match
group by trial_id
order by patients desc
;
