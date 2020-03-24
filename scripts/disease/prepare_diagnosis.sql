/**** diagnosis
Requires:
    cohort, cplus, dev_patient_info
Results:
    latest_icd
Settings:
    cancer_type
*/
drop table if exists _dx;
create temporary table _dx as
select distinct mrn
, age_in_days_key as age_in_days
, DESCRIPTION
, context_diagnosis_code, context_name
, diagnosis_role, diagnosis_weighting_factor
from _person
join ${dmsdw}.fact using (person_key)
join ${dmsdw}.b_diagnosis using (diagnosis_group_key)
join ${dmsdw}.fd_diagnosis rd using (diagnosis_key)
where context_name in ('ICD-10', 'ICD-9')
;
/*
select count(*), count(distinct mrn)
from _dx
;
'IMO', 'MSDRG', 'APRDRG', 'APRDRG MDC', 'NYDRG', 'DRG','TDS')
order by mrn, age_in_days, context_name
*/

drop table if exists latest_icd;
create table latest_icd as
select mrn, context_diagnosis_code icd_code, context_name
, description, age_in_days
from (select *, row_number() over (
        partition by mrn, context_diagnosis_code
        order by age_in_days desc nulls last, description)
    from _dx
    )
where row_number=1
;
/*
select count(*), count(distinct mrn) from latest_icd;
	-- ~600K, ~17K
*/
