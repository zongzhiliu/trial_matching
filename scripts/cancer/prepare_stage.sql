/***
 * stage:  using $cancer_type
 */
--set search_path=ct_${cancer_type};

drop table if exists stage;
create table stage as
with _stage as (
    select person_id, overall_stage stage
        , regexp_substr(stage, '^[0IV]+') stage_base
        , regexp_substr(stage, '[A-C].*') stage_ext
    from demo
    join cplus_from_aplus.cancer_diagnoses cd using (person_id)
    join prod_references.cancer_types using (cancer_type_id)
    where nvl(cd.status,'') != 'deleted'
        and cancer_type_name='${cancer_type}'
)
select person_id
, case when stage in ('', 'Not Reported') then NULL else stage end stage
, case when stage_base='' then NULL else stage_base end stage_base
, case when stage_ext='' then NULL else stage_ext end stage_ext
from _stage
;
create view qc_stage as
select stage_base, count(distinct person_id) from stage 
group by stage_base
order by stage_base
;
select * from qc_stage;
select count(*) stage_records, count (distinct person_id) patients from stage where stage is not null;

