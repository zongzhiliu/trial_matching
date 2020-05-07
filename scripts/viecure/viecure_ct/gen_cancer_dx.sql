/**** Results: viecure_ct.latest_icd
Requires:
    cancer_type_icd, viecure_ct.patient_diagnosis
*/
drop table if exists all_dx;
create table all_dx as
select id diagnosis_id
, pt_id person_id
, 'ICD' as dx_code_type
, diagnosis_code dx_code
, date_diagnosed dx_date
, diagnosis_text 
from viecure_emr.patient_diagnosis_current
WHERE diagnosis_code is not null
;
--qc
select count(distinct person_id) FROM all_dx ad ; -- original 143044 After clear null 141500

drop table if exists latest_icd;
create table latest_icd as
select diagnosis_id, person_id
, dx_code_type, dx_code, dx_date
, diagnosis_text 
from (select *, row_number() over (
        partition by person_id, dx_code
        order by dx_date desc nulls last)
    from all_dx
    --where dx_code_type = 'ICD'
)
where row_number=1
;
--qc
select count(*) FROM latest_icd ; --139394 -- 138042

drop table if exists cancer_dx;
create table cancer_dx as
select diagnosis_id, person_id, cancer_type_name, dx_code icd_code, dx_date
from ( select *, row_number() over (
		partition by person_id, cancer_type_name
		order by dx_date
	) from all_dx ad 
	join ct.ref_cancer_icd r on ct.py_contains(dx_code, icd_10) or ct.py_contains(dx_code, icd_9)
)
where row_number = 1;
--qc
select count(distinct person_id) patients, cancer_type_name 
from cancer_dx cd
GROUP BY cancer_type_name;

drop table if exists cancer_stage;
create table cancer_stage as
with _cancer as(
	select person_id, diagnosis_id 
	, cancer_type_name
	, dx_code
	, stage_list.description as stage
	, t, n, m
	, date_staged
	from viecure_emr.patient_stage 
	join viecure_ct.all_dx using (diagnosis_id)
	join viecure_emr.stage_list on stage_list_id=stage_list.id
	join ct.ref_cancer_icd r on ct.py_contains(dx_code, icd_10) or ct.py_contains(dx_code, icd_9)
	WHERE cancer_type_name != 'PAN'
)
SELECT * 
FROM (SELECT *, row_number() over (
		PARTITION BY person_id 
		ORDER BY date_staged DESC NULLS last
	) FROM _cancer
)
WHERE row_number = 1;

-- later impute stage from t, n, m

drop table cancer_histology;
create table cancer_histology as;
select person_id
, cancer_type_name
, icd_code
, histology_behavior.description as histologic_name
, code as histologic_icdo
, histologic_grade
, date_staged
from cancer_dx  
join viecure_emr.patient_histology using (diagnosis_id)
join viecure_emr.histology_behavior using (histology_id)
;
