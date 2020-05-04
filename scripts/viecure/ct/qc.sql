-- all ct_test_name should have 1+ loinc matched
select count(*), count(distinct ct_test_name) from ref_test;
select count(*), count(distinct ct_test_name) from ref_test join ref_test_loinc using (ct_test_name);
