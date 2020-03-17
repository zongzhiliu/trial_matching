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
/* later
create table _ie_match as
select trial_id, person_id, attribute_id
, (inclusion is not null) as ie
, nvl(inclusion, exclusion) as value
, nvl(ie_mandatory, mandated='yes') as mandatory
, attribute_match
*/
drop table if exists trial_patient_match cascade;

-- match adjusted with i/e and mandatory
drop table if exists _match_adjusted cascade;
create table _match_adjusted as
select trial_id, person_id, attribute_id
, (inclusion is not null) as ie
, nvl(inclusion, exclusion) as ie_value
--, (mandated='yes') as mandatory
, nvl(ie_mandatory, attribute_mandated='yes') as mandatory
, attribute_match
, nvl(attribute_match, not mandatory) as match_amputed
, case when ie then match_amputed
    else not match_amputed
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

create table _crit_logic as
with tmp as (
    select attribute_id, logic
    , split_part(logic, '/', 1) p1
    , split_part(logic, '/', 2) p2
    from crit_attribute_used
)
select attribute_id, logic
, case when p1 is null or p1='' then attribute_id else p1 end logic_l1
, case when p2 is null or p2='' then attribute_id else p2 end logic_l2
from tmp
order by logic
;
/*
select trial_id, person_id, attribute_id
, match_adjusted
from _match_adjusted
join (select trial_id, count(distinct attribute_id) ca
    from _match_adjusted
    where attribute_id ~ 'BCA(2[8-9]|3[0-1])'
    group by trial_id
    having (ca=4)) using (trial_id)
where attribute_id ~ 'BCA(2[8-9]|3[0-1])'
and person_id=126673
order by person_id, trial_id, attribute_id
;
*/
create table trial_patient_match as
with _crit_l2 as (
    select trial_id, person_id, logic_l1, logic_l2
    , bool_and(match_adjusted) l2_match
    from _match_adjusted
    join _crit_logic using (attribute_id)
    group by trial_id, person_id, logic_l1, logic_l2
), _crit_l1 as (
    select trial_id, person_id, logic_l1
    , bool_or(l2_match) l1_match
    from _crit_l2
    group by trial_id, person_id, logic_l1
)
select trial_id, person_id
, bool_and(l1_match) patient_match
from _crit_l1
group by trial_id, person_id
;

/* old
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
*/

drop view if exists v_trial_patient_count;
create view v_trial_patient_count as
select trial_id
, sum(patient_match::int) patients
from trial_patient_match
group by trial_id
order by patients desc
;
