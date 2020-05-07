
-- to mv latest_loinc here later
create view latest_loinc as select * from viecure_ct.latest_loinc;

drop table if exists latest_test cascade;
create table latest_test as
select person_id, ct_test_name
, loinc_code
, test_time
, source_value, uom_id
, value_float
from (select *, row_number() over (
        partition by person_id, ct_test_name
        order by test_time desc nulls last, value_float) -- tie breaker
    from latest_loinc
    join ref_test_loinc on loinc_num=loinc_code
    )
where row_number=1
;

