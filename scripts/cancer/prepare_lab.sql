/*** * labs
Requires:
    cohort, prod_msdw.all_labs
Results:
    _loinc_lab, latest_lab
*/
drop table if exists _loinc_lab;
create table _loinc_lab as
select distinct person_id, result_date::date
, loinc_code, loinc_display_name
, value_float, value_range_low, value_range_high, unit
, source_value, source_unit
from prod_msdw.all_labs
join cohort using (person_id)
where loinc_code is not null
    and value_float is not null
;

drop table if exists latest_lab;
create table latest_lab as
select person_id, result_date
, loinc_code, loinc_display_name
, value_float, unit
, source_unit, source_value
from (select *, row_number() over (
        partition by person_id, loinc_code
        order by result_date desc nulls last, value_float desc nulls last)
        from _loinc_lab)
where row_number=1
order by person_id, result_date, loinc_code
;

create view qc_lab as
select loinc_code, loinc_display_name, unit
, count(*) records, count(distinct person_id) patients
from latest_lab
;
select count(distinct person_id) from latest_lab
;
/*** qc
select * from _all_loinc where lower(loinc_display_name) ~ 'testosterone'; --'prostate';
*/

