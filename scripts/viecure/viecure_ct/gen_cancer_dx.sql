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
;
select count(*) FROM all_dx ad ; --143044

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
select count(*) FROM latest_icd ; --139394

create table cancer_dx as
select person_id, cancer_type_name, dx_code icd_code, dx_date
from latest_icd d
join ct.ref_cancer_icd r on ct.py_contains(nvl(dx_code,''), icd_10) -- or ct.py_contains(d.dx_code, icd_9)
;
create table cancer_stage as
select person_id
, cancer_type_name
, dx_code, dx_code_type
, stage_overall
, t, n, m
, date_staged
from patient_stage 
join all_dx using (diagnosis_id)
join stage_list on stage_list_id=stage_list.id
;
-- later impute stage from t, n, m

create table cancer_histology as
select person_id
, cancer_type_name
, dx_code, dx_code_type
, histologic_name, histologic_icdo
, histologic_grade
, date_staged
from patient_stage 
join all_dx using (diagnosis_id)
join stage_list on stage_list_id=stage_list.id
;
select count(*) records, count(distinct person_id) patients from latest_icd;
/*qc
select count(distinct person_id) from _all_dx; --v1:4997 v2:5430 v3:3446
*/

