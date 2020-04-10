/***
 * match vital: weight, bmi, bloodpressure
 * require: vital, vital_bmi
 */
drop table if exists _latest_bmi;
create table _latest_bmi as
select person_id, weight_age, weight_kg, height_m, bmi
from (select *, row_number() over (
        partition by person_id
        order by -weight_age, -bmi)
    from vital_bmi
    )
where row_number=1
;
drop table _p_a_t_weight;
create table _p_a_t_weight as
select attribute_id, trial_id, person_id
, ie_value::float as value
, weight_kg::float as patient_value
, case attribute_id
    when 301 --'max_body weight'
        then patient_value<=value
    when 300 --'min_body weight'
        then patient_value>=value
    end as match
from trial_attribute_used
cross join _latest_bmi
where attribute_id in (300, 301)
--    and nvl(inclusion, exclusion) ~ '^[0-9]+(\\.[0-9]+)?$' --Fixme
;
/*-- check
select attribute_name, attribute_value, clusion, count(distinct person_id)
from _p_a_t_weight join crit_attribute_used using (attribute_id)
where match
group by attribute_name, attribute_value, clusion
order by attribute_name, attribute_value, clusion::int
;
*/
drop table if exists _latest_blood_pressure;
create table _latest_blood_pressure as
with syst as (
    select *, row_number() over (
            partition by person_id
            order by -age_in_days, -value)
    from vital
    where procedure_description='Systolic Blood Pressure'
        and value ~'^[0-9]+(\\.[0-9]+)?$' --float: '152/'
)
, last_syst as (
    select person_id, age_in_days, value as systolic
    from syst where row_number=1
) --select * from last_syst;
, diast as (
    select *, row_number() over (
            partition by person_id
            order by -age_in_days, -value)
    from vital
    where procedure_description='Diastolic Blood Pressure'
        and value ~'^[0-9]+(\\.[0-9]+)?$'  -- debug: invalid digit '/65'
)
, last_diast as (
    select person_id, age_in_days, value as diastolic
    from diast where row_number=1
)
select *
from last_syst
join last_diast using (person_id, age_in_days)
;

drop table _p_a_t_blood_pressure;
create table _p_a_t_blood_pressure as
select attribute_id, trial_id, person_id
, ie_value::int value
, case attribute_id
    when 268 then systolic::int --max
    when 269 then diastolic::int --max
    end as patient_value
, patient_value<=value as match
from trial_attribute_used t
join crit_attribute_used a using (attribute_id)
cross join _latest_blood_pressure p
where attribute_id in (268, 269)
--    and nvl(inclusion, exclusion) ~ '^[0-9]+$' --Fixme
;
/*-- check
select attribute_name, attribute_value, clusion, count(distinct person_id)
from _p_a_t_blood_pressure join crit_attribute_used using (attribute_id)
where match
group by attribute_name, attribute_value, clusion
order by attribute_name, attribute_value, clusion::int
;
*/

