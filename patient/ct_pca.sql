set search_path=ct_lca;

create table _all_labs as
select l.*
from demo
join prod_msdw.all_labs l using (person_id)
;

create table _all_loinc as
select distinct loinc_code, loinc_display_name, unit
from _all_labs
;

-- 163
select * from _all_loinc;

select *
from ct.reference_NSCLC_lab_test
left join _all_loinc using (loinc_code)
;
