drop table if exists _patient_tests cascade;
create table _patient_tests as
select id, pt_id, code_system_type_id, code, test_time, value, uom_id from viecure_emr.patient_tests_current union
select id, pt_id, code_system_type_id, code, test_time, value, uom_id from viecure_emr.patient_tests_hx
;
drop table if exists loinc_test cascade;
create table loinc_test as
select p.id test_id, pt_id person_id
, code loinc_num, long_common_name
, test_time
, value, uom_id
from _patient_tests p
join viecure_emr.loinc on code=loinc_num
;

create view qc_loinc_test as
select loinc_num, long_common_name
, count(*) records, count(distinct person_id) patients
from loinc_test
group by loinc_num, long_common_name
order by patients desc, records desc
;

drop table if exists latest_test cascade;
create table latest_test as
select person_id
, loinc_num, long_common_name
, test_time
, value source_value, uom_id
, regexp_substr(value, '-?[0-9]+([.][0-9]+)?')::float value_float
from (select *, row_number() over (
        partition by person_id, loinc_num
        order by test_time desc nulls last, value) -- tie breaker
    from loinc_test
    where btrim(value) ~ '^[<>=-]*[0-9]+([.][0-9]+)?$'
    )
where row_number=1
;
drop view qc_latest_test_excluded_values;
create view qc_latest_test_excluded_values as
select value
, count(*) records from loinc_test
where btrim(value) !~ '^[<>=-]*[0-9]+([.][0-9]+)?$'
group by value
order by records desc, value
;
/*
select * from qc_latest_test_excluded_values;
select '1,646.1' ~ '^[<>=-]*[0-9]+([.][0-9]+)?$';
select '1,646.01'::float;
*/

select count(*), count(distinct person_id) from latest_test;
select count(*), count(distinct person_id) from loinc_test;
select count(*), count(distinct pt_id) from _patient_tests;
