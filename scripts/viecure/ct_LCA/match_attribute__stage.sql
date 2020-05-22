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


/*** match attribute for cancer stage
Requires: cohort, crit_attribute_used, trial_attribute_used
    stage
Results: _p_a_t_stage
*/
drop table if exists _p_a_t_stage cascade;
create table _p_a_t_stage as
with cau as (
    select attribute_id, code_type, code
    , attribute_value--, attribute_value_norm
    from crit_attribute_used
    where code_type in ('stage_base', 'stage_like')
), tau as (
    select attribute_id, trial_id
    , ie_value
    from trial_attribute_used
    --where ie_value = 'yes'
)
select person_id, trial_id, attribute_id
, bool_or(case code_type
    when 'stage_base' then stage_base = code
    when 'stage_like' then stage like code
    end) as match
from (stage cross join cau)
join tau using (attribute_id)
group by person_id, trial_id, attribute_id
;

select attribute_id, attribute_name, code, attribute_value, match
, count(distinct person_id) patients
from _p_a_t_stage
join crit_attribute_used using (attribute_id)
where match
group by attribute_id, attribute_name, code, attribute_value, match
order by attribute_id, match
;
