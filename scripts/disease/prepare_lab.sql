/*** * labs
Requires: cohort
    , ct.all_labs
Results:
    loinc_lab, latest_lab
*/
drop table if exists loinc_lab;
create table loinc_lab as
select distinct mrn
, age_in_days_key::float as age_in_days  -- they are minus and floats??
, loinc_code, loinc_display_name
, value_float, value_range_low, value_range_high, unit
, source_value, source_unit
from ct.all_labs
join cohort using (mrn)
where loinc_code is not null
    and value_float is not null
;

drop table if exists latest_lab;
create table latest_lab as
select mrn person_id
, dateadd(day, age_in_days::int, date_of_birth)::date lab_date
, loinc_code, loinc_display_name
, value_float, unit
, source_unit, source_value
from (select *, row_number() over (
        partition by mrn, loinc_code
        order by age_in_days desc nulls last, value_float desc nulls last)
    from loinc_lab)
join demo using (mrn)
where row_number=1
--order by mrn, age_in_days, loinc_code
;

/*** qc
create table _all_loinc as
select distinct loinc_code, loinc_display_name, unit
from latest_lab
;

select count(distinct person_id) from latest_lab; --11417
select * from _all_loinc where lower(loinc_display_name) ~ 'testosterone'; --'prostate';
*/

