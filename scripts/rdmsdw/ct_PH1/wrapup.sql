/* deliver the table requested
pt_id, (initial)dxate_ph1, age, gender, race,  death_date, ab(nomal)_kidney_indicator, initial_kidney_date (afterPH1dx), liver_transplantation_indicator, liver__transplantation_date(afterPH1dx)
*/
-- abnormal renal funcition test (ARFT)
--drop table _arft cascade;
create temporary table _arft as
with egfr as (
    select *
    , btrim(replace(replace(test_result_value
        , '<', '')
        , '>', '')) test_result_value_pure
    from loinc_lab
    where loinc='48642-3' --eGFR
        and test_result_value_pure ~ '^([0-9]+([.][0-9]+)?)$'
)
select *
from egfr
where test_result_value_pure::float <= 45
;
/*
select count(*), count(distinct mrn) from _arft;
    -- 73 patients
select _arft.*, dx_date, idx.age_in_days dx_age_in_days
from _arft join initial_disease_dx idx using (mrn);
*/

-- liver transplant (LT)
--drop table _lt cascade;
create temporary table _lt as
select *
from dx
where context_diagnosis_code ~ '^(Z94[.]?4|V42[.]?7)'
;
/*
select count(*), count(distinct mrn) from _lt;
    -- 584, 10 patients
*/

-- first abnormal renal function test after initial_dx
drop table master_sheet cascade;
create table master_sheet as
with earliest_arft as (
    select mrn, min(age_in_days) as age_in_days
    from _arft group by mrn
), earliest_lt as (
    select mrn, min(age_in_days) as age_in_days
    from _lt group by mrn
), init_arft as (
    select mrn, min(_arft.age_in_days) as age_in_days
    from _arft join initial_disease_dx idx using (mrn)
    where _arft.age_in_days > idx.age_in_days
    group by mrn
), init_lt as (
    select mrn, min(_lt.age_in_days) as age_in_days
    from _lt join initial_disease_dx idx using (mrn)
    where _lt.age_in_days > idx.age_in_days
    group by mrn
)
select mrn pt_id
, idx.dx_date as initial_dx_date
, date_of_birth_truncated date_of_birth
, (datediff(day, date_of_birth, current_date)/365.25)::int age
, gender
, race_name race
, nvl(ethnicity, 'Unknown') ethnicity
, deceased deceased_indicator
, dateadd(day, earliest_arft.age_in_days::int, date_of_birth) earliest_abnormal_kidney_date
, (earliest_abnormal_kidney_date is not null) as earliest_abnormal_kidney_indicator
, dateadd(day, init_arft.age_in_days::int, date_of_birth) abnormal_kidney_date
, (abnormal_kidney_date is not null) as abnormal_kidney_indicator
, dateadd(day, earliest_lt.age_in_days::int, date_of_birth) earliest_liver_transplant_date
, (earliest_liver_transplant_date is not null) as earliest_liver_transplant_indicator
, dateadd(day, earliest_lt.age_in_days::int, date_of_birth) liver_transplant_date
, (liver_transplant_date is not null) as liver_transplant_indicator
from demo_plus
join initial_disease_dx idx using (mrn)
left join earliest_arft using (mrn)
left join earliest_lt using (mrn)
left join init_arft using (mrn)
left join init_lt using (mrn)
order by dx_date desc
;
create view v_master_sheet as
select *
from master_sheet
order by initial_dx_date desc
;
/*
select count(distinct pt_id) from master_sheet where earliest_abnormal_kidney_date is not null;
    -- 73
select count(distinct pt_id) from master_sheet where earliest_liver_transplant_date is not null;
    -- 10
select * from master_sheet where earliest_liver_transplant_date is not null order by earliest_liver_transplant_date;
*/
