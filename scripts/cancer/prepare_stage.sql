/***
 * stage:  using $cancer_type
 */
drop table stage;
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
select person_id, stage
, case when stage_base='' then NULL else stage_base end stage_base
, case when stage_ext='' then NULL else stage_ext end stage_ext
from _stage
;
/*qc
select stage_base, count(distinct person_id) from stage 
group by stage_base
order by stage_base
; --13220 no stage!!
*/


