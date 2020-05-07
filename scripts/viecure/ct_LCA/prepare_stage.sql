/***
 * stage:  using $cancer_type
 */
--set search_path=ct_${cancer_type};

drop table if exists stage;
create table stage as
with _stage as (
    select person_id, stage
        , regexp_substr(stage, '^[0IV]+') stage_base
        , regexp_substr(stage, '[A-C].*') stage_ext
    from demo
    join viecure_ct.all_dx using (person_id)
    join viecure_ct.cancer_stage using (person_id)
        where cancer_type_name='LCA'
)
select person_id
, case when stage in ('', 'Not Reported') then NULL else stage end stage
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


