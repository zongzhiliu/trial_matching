/* deliver the table requested
pt_id, (initial)dxate_ph1, age, gender, race,  death_date, ab(nomal)_kidney_indicator, initial_kidney_date (afterPH1dx), liver_transplantation_indicator, liver__transplantation_date(afterPH1dx)
*/
-- abnormal renal funcition test (ARFT)
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
limit 9
;
select count(*), count(distinct mrn) from _arft;
    -- only 8 patients

-- liver transplant (LT)
create temporary table _lt as
select *
from dx
where context_diagnosis_code ~ '^(Z94[.]?4)'
;
select count(*), count(distinct mrn) from _lt;
    -- only 10 patients

-- first abnormal renal function test after initial_dx
create view master_sheet as
with init_arft as (
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
, idx.dx_date as inital_dx_date
, (datediff(day, date_of_birth, current_date)/365.25)::int age
, gender
, race_raw race
, deceased deceased_indicator
, dateadd(day, init_arft.age_in_days::int, date_of_birth) abnormal_kidney_date
, abnormal_kidney_date is not null as abnormal_kidney_indicator
, dateadd(day, init_lt.age_in_days::int, date_of_birth) liver_transplant_date
, liver_transplant_date is not null as liver_transplant_indicator
from demo
join initial_disease_dx idx using (mrn)
left join init_arft using (mrn)
left join init_lt using (mrn)
order by dx_date desc
;
select * from master_sheet;
