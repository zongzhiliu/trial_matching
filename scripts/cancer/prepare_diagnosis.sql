/**** diagnosis
Requires:
    cohort, cplus, dev_patient_info
Results:
    latest_icd
Settings:
    cancer_type
*/
drop table if exists latest_icd;
create table latest_icd as
with _all_dx as (
    select distinct person_id, dx_date, icd, icd_code, description
    from (select medical_record_number mrn, dx_date
        , icd, context_diagnosis_code icd_code, description
        from dev_patient_info_${cancer_type}.all_diagnosis) d
    join cplus_from_aplus.person_mrns using (mrn)
    join cohort using (person_id)
)
select person_id, icd_code, icd as context_name, description, dx_date
from (select *, row_number() over (
        partition by person_id, icd_code
        order by dx_date desc nulls last, description)
    from _all_dx
    )
where row_number=1
;
/*qc
select count(distinct person_id) from _all_dx; --v1:4997 v2:5430 v3:3446
select count(*) from latest_icd; --v1: 316791, v2: 327904 v3: 199662
*/


