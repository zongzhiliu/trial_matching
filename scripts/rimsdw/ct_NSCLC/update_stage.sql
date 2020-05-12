/***
 * stage rescued with dev_patient_clinical.imputed_stage.
 */

drop table if exists stage_plus cascade;
create table stage_plus as
select person_id
, year_of_diagnosis dx_year, month_of_diagnosis dx_month, day_of_diagnosis dx_day
, case when overall_stage in ('', 'Not Reported', 'Not Available') then --Occult Carcinoma is defined TXN0M0
    NULL else overall_stage end stage_extracted
, imputed_stage_optimized as stage_imputed
from cohort
join cplus_from_aplus.cancer_diagnoses cd using (person_id)
join prod_references.cancer_types using (cancer_type_id)
join dev_patient_clinical_lca.imputed_stage using (person_id)
where nvl(cd.status,'') not in ('deleted', 'added_by_user_and_deleted')
    and cancer_type_name='${cancer_type}'
;


drop view if exists stage;
create view stage as
select person_id
, nvl(stage_extracted, stage_imputed) as stage
, regexp_substr(stage, '^[0IV]+') stage_base
from stage_plus
;

select ct.assert (bool_and(stage='0' or stage like 'I%')
, 'stage startswith 0 or I') from stage
;

with a as (
    select count(*) from stage where stage is not null
), e as (
    select count(*) from stage_plus where stage_extracted is not null
)
select a.count, e.count, ct.assert(a.count>e.count, 'imputing rescues some stage')
from a cross join e
;

select count(*) stage_records, count (distinct person_id) patients from stage_plus where stage is not null;
select count(*) stage_records, count (distinct person_id) patients from stage_plus where stage_extracted is not null;
