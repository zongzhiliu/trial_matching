/* > latest_stage (person_id, stage, stage_base)
Input: cplus.cancer_diagnoses_mm
*/
\set cancer_type MM

drop table if exists stage cascade;
create table stage as
with _stage as (
    select person_id, cancer_diagnosis_id
        , case when ds_stage not in ('', 'Not Reported', 'Unknown') then ds_stage end ds
        , case when iss_stage not in ('', 'Not Reported', 'Unknown') then iss_stage end iss
        , nvl(iss, ds) stage
        , regexp_substr(stage, '^[0IV]+') stage_base
        , regexp_substr(stage, '[A-C].*') stage_ext
    from cohort
    join cplus_from_aplus.cancer_diagnoses cd using (person_id)
    join cplus_from_aplus.cancer_diagnoses_mm mcd using (cancer_diagnosis_id)
    join prod_references.cancer_types using (cancer_type_id)
    where nvl(cd.status,'') not like '%deleted'
        and cancer_type_name=:'cancer_type'
)
select person_id, cancer_diagnosis_id
, stage, stage_base, stage_ext
from _stage
;

drop table if exists latest_stage cascade;
create table latest_stage as
select *
from (select *, row_number() over (
        partition by person_id
        order by -year_of_diagnosis, -month_of_diagnosis, -day_of_diagnosis, overall_stage)
        from stage
        join cplus_from_aplus.cancer_diagnoses using (cancer_diagnosis_id, person_id))
where row_number=1
    and stage is not null
;

create view qc_stage as
select stage_base, count(distinct person_id) from stage
group by stage_base
order by stage_base
;
select * from qc_stage;
select count(*) stage_records, count (distinct person_id) patients from stage where stage is not null;


