-- patient_diagnosis
select count(*), count(distinct pt_id), count(distinct diagnosis_code)
from dbo.patient_diagnosis_current;

-- patient_medications
select count(*), count(distinct patient_id), count(distinct code) 
FROM (
    select patient_id, code from [dbo].[patient_medications_hx] union
    select patient_id, code from [dbo].[patient_medications_current]) as tmp
;

--mar
select count(*), count(distinct patient_id), count(distinct drug_name) 
FROM [dbo].[mar]
;

-- patient_tests
select count(*), count(distinct pt_id), count(distinct code) 
FROM (
    select pt_id, code from [dbo].[patient_tests_hx] union
    select pt_id, code from [dbo].[patient_tests_current]) as tmp
;

select code, shortname, long_common_name
 ,count(distinct pt_id) patients
 from patient_tests_current 
 join loinc on code=loinc_num 
 where lower(long_common_name) like '%aminotransferase%'
	and value is not null
 group by code, shortname, long_common_name
 ;

-- patient_gene_report
select count(*), count(distinct pt_id) FROM [dbo].[patient_gene_report_details]

-- patient_history
select count(*), count(distinct pt_id), count(distinct description)  FROM [dbo].[patient_history_items]
