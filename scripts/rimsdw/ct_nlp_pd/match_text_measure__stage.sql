/***
Requires: crit_attribute_used (using attribute_id and code_ext)
    cohort, stage
Results:
    pa_stage
*/
drop table if exists _p_a_stage cascade;
create table _p_a_stage as
with cau as (
    select attribute_id, code, code_ext
    from crit_attribute_used
    where code_type='text_like' and code like 'stage%'
)
select person_id, attribute_id
, listagg(stage, '| ') as patient_value
, bool_or (case code
     when 'stage_base' then stage_base like code_ext
     when 'stage' then stage like code_ext
     end) as match
from cohort join latest_stage using (person_id)
cross join cau
group by person_id, attribute_id
;

create view qc_match_stage as
select attribute_name, attribute_value, count(*)
from _p_a_stage join crit_attribute_used using (attribute_id)
where match
group by attribute_name, attribute_value
order by attribute_name, attribute_value
;
select * from qc_match_stage;

