/*** > stage
Input: cohort, cplus.cancer_diagnoses
 */

drop table if exists stage cascade;
create table stage as
with _stage as (
    select person_id, overall_stage stage
        , cancer_diagnosis_id
        , regexp_substr(stage, '^[0IV]+') stage_base
        , regexp_substr(stage, '[A-C].*') stage_ext
    from cohort
    join cplus_from_aplus.cancer_diagnoses cd using (person_id)
    join prod_references.cancer_types using (cancer_type_id)
    where nvl(cd.status,'') not like '%deleted'
        and cancer_type_name='${cancer_type}'
)
select person_id
, cancer_diagnosis_id
, case when stage in ('', 'Not Reported', 'Not Applicable') then NULL else stage end stage
, case when stage_base='' then NULL else stage_base end stage_base
, case when stage_ext='' then NULL else stage_ext end stage_ext
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


