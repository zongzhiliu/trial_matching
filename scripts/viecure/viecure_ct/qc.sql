-- CrCl values are all (N/A, ---)
select distinct value from viecure_ct.loinc_test where loinc_num='35592-5' limit 99;

with tmp as (
    select id, pt_id, code_system_type_id, code, test_time, value, uom_id from viecure_emr.patient_tests_current union
    select id, pt_id, code_system_type_id, code, test_time, value, uom_id from viecure_emr.patient_tests_hx
)
join (select id, count(*)
	from tmp
	group by id having count(*)>1) using (id)
order by id;

select * from viecure_ct._patient_tests
-- same id has two rows with different patient_id!
select count(*), count(distinct id) from viecure_ct._patient_tests;
