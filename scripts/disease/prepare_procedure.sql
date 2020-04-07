/***
Results: _proc, latest_proc
Requires: _person, demo, dmsdw
create table _kinds_of_procedures as
select distinct bp.procedure_role
    , fp.procedure_description
    , fp.context_procedure_code
    , fp.context_name
    , level2_event_name, level3_action_name, level4_field_name, value
from _person
join ${dmsdw}.fact f using (person_key)
join ${dmsdw}.d_metadata m using (meta_data_key)
join ${dmsdw}.b_procedure bp using (procedure_group_key)
join ${dmsdw}.fd_procedure fp using (procedure_key)
;
*/
--create table last_procedure as
/* too slow
create table _proc as
select mrn, f.age_in_days_key::int as age_in_days
, bp.procedure_role
, fp.procedure_description
, fp.context_procedure_code
, fp.context_name
, f.value
, u.unit_of_measure
, level2_event_name, level3_action_name, level4_field_name
from _person dp
join ${dmsdw}.fact f using (person_key)
join ${dmsdw}.d_metadata m using (meta_data_key)
join ${dmsdw}.d_unit_of_measure u using (uom_key)
join ${dmsdw}.b_procedure bp using (procedure_group_key)
join ${dmsdw}.fd_procedure fp using (procedure_key)
    where level3_action_name not in ('Canceled', 'Pended') -- more later
;
*/

/*
create table _surg as
select distinct *
from _proc
where lower(procedure_role)~'surg' or lower(level2_event_name) ~ 'surg'
;

create table surg as
select mrn, age_in_days
, context_procedure_code, context_name, procedure_description, level2_event_name
, listagg(level3_action_name, ' |') within group (order by level3_action_name) level3_action_names
, count(*) records
from _surg
group by mrn, age_in_days
, context_procedure_code, context_name, procedure_description, level2_event_name
;

select mrn, age_in_days, procedure_description, level2_event_name, level3_action_name, level4_field_name
, value, unit_of_measure, context_name, context_procedure_code
from _surg
order by mrn, age_in_days, procedure_description, level2_event_name, level3_action_name, level4_field_name
;
*/

drop table if exists latest_proc;
create table latest_proc as
with _proc as (
    select mrn, f.age_in_days_key::int as age_in_days
    -- , bp.procedure_role
    , fp.procedure_description
    , fp.context_procedure_code
    , fp.context_name
    -- , f.value, u.unit_of_measure
    -- , level2_event_name, level3_action_name, level4_field_name
    from _person dp
    join ${dmsdw}.fact f using (person_key)
    join ${dmsdw}.d_metadata m using (meta_data_key)
    -- join ${dmsdw}.d_unit_of_measure u using (uom_key)
    join ${dmsdw}.b_procedure bp using (procedure_group_key)
    join ${dmsdw}.fd_procedure fp using (procedure_key)
        where level3_action_name not in ('Canceled', 'Pended') -- more later
)
select mrn, mrn person_id
, context_name, context_procedure_code
, procedure_description
, dateadd(day, age_in_days, dob_low)::date as proc_date
from (select *, row_number() over (
        partition by mrn, context_name, context_procedure_code
        order by -age_in_days)
        --, procedure_role
        --, level2_event_name, level3_action_name, level4_field_name
        --, value, unit_of_measure)
    from _proc
)
join demo using(mrn)
where row_number=1
;

