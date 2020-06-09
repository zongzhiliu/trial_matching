```sql
create table all_dx as
select distinct mrn
, age_in_days_key as age_in_days
, DESCRIPTION
, context_diagnosis_code, context_name
, diagnosis_role, diagnosis_weighting_factor
from ${dmsdw}.d_person
join ${dmsdw}.fact using (person_key)
join ${dmsdw}.b_diagnosis using (diagnosis_group_key)
join ${dmsdw}.fd_diagnosis rd using (diagnosis_key)
where context_name in ('ICD-10', 'ICD-9')
    and person_key>3 and data_state_key=1
;
