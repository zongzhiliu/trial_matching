/***
Requires:
    crit_attribute_used
    _master_sheet
Results:
    trial_patient_match
Settings:
    @set cancer_type=
    SET search_path=ct_${cancer_type};
*/
drop table if exists trial_patient_match cascade;
drop view if exists v_trial_patient_count cascade;
drop table if exists _ie_match cascade;
drop table if exists _crit_logic cascade;

-- match adjusted with i/e and then mandatory
create table _ie_match as
select trial_id, person_id, attribute_id
, (inclusion is not null) as ie
, nvl(inclusion, exclusion) as ie_value
, attribute_match
, mandatory
, case when ie then attribute_match
    else not attribute_match
    end as match_adjusted
, nvl(match_adjusted, not mandatory) as match_imputed
from _master_sheet
;
/*
select * from _ie_match
order by person_id, trial_id, attribute_id
limit 100;
*/

-- break the logic into two levels
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

-- collase the ie_match to levels of logic
drop table if exists _crit_l1;
create temporary table _crit_l1 as
with _crit_l2 as (
    select trial_id, person_id, logic_l1, logic_l2
    , bool_and(match_imputed) l2_match
    from _ie_match
    join _crit_logic using (attribute_id)
    group by trial_id, person_id, logic_l1, logic_l2
)
select trial_id, person_id, logic_l1
, bool_or(l2_match) l1_match
from _crit_l2
group by trial_id, person_id, logic_l1
;

/* debug
--create temporary table _c2p_wo_drug as
create temporary table _c2p_w_all as
with tmp as(
select trial_id, person_id
, bool_and(l1_match) patient_match
from _crit_l1
left join crit_attribute_used cau on cau.attribute_id=logic_l1
--where logic_l1 != 'mut.or'
--where code_type not like 'drug%'
group by trial_id, person_id
)
select trial_id, sum(patient_match::int) patients
from tmp
--where patient_match
group by trial_id
order by patients desc nulls last
;

select trial_id, a.patients a_patients, xdrug.patients xdrug_patients
from _c2p_w_all a
join _c2p_wo_drug xdrug using (trial_id)
order by a.patients desc nulls last
;
*/

create table trial_patient_match as
select trial_id, person_id
, bool_and(l1_match) patient_match
from _crit_l1
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
/*
select * from v_trial_patient_count;
*/
