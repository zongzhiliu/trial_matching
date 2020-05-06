-- CrCl values are all (N/A, ---)
select distinct value from viecure_ct.loinc_test where loinc_num='35592-5' limit 99;

-- same id has two rows with different patient_id!
select count(*), count(distinct id) from viecure_ct._patient_tests;
select * from viecure_ct._patient_tests
join (select id, count(*) 
	from viecure_ct._patient_tests 
	group by id having count(*)>1) using (id)
order by id;

