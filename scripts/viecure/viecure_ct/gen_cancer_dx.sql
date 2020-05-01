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
, date_ dx_date, icd, icd_code, description
from viecure_emr.patient_diagnosis_current
;

drop table if exists latest_icd;
create table latest_icd as
select person_id, dx_code icd_code, dx_code_type as context_name, description, dx_date
from (select *, row_number() over (
        partition by person_id, dx_code
        order by dx_date desc nulls last, description)
    from _all_dx
    where dx_code_type like 'ICD%'
    )
where row_number=1
;

create table cancer_dx as
with tmp as (
    select person_id
    , cancer_type_name
    , dx_code, dx_code_type
    , dx_date
    from all_dx d
    join ct.cancer_type_id c on ct.py_contains(d.dx_code, icd_9) or ct_contains(d.dx_code, icd_10)
    where d.dx_code_type like 'ICD%'
)
select person_id, cancer_type_name, dx_code icd_code, dx_date
from (select *, row_number() over (
        partition by person_id, dx_code
        order by dx_date)
    from tmp)
where row_number=1
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

