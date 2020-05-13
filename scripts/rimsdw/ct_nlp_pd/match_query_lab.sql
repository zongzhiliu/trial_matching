/* > _p_a_query_lab
Requires: _p_query_lab_... tables
*/

drop table if exists _p_a_query_lab cascade;
create table _p_a_query_lab as
with cau as (
    select attribute_id, code_type, code
    --, regexp_substr(attribute_value, '[0-9]+([.][0-9]+)?')::float crit_value
    --, code_ext as comp
    --, code_transform
    from crit_attribute_used
    where code_type = 'query_lab'
)
select person_id, attribute_id
, case when code like 'ast_or%' then
        ast_or.match
    when code like 'alt_or%' then
        alt_or.match
    when code like 'tbili_or%' then
        tbili_or.match
    when code ilike 'aof%' then
        aof.match
    end as match
from (cohort cross join cau)
join _p_query_lab_ast_or_livermet ast_or using (person_id)
join _p_query_lab_alt_or_livermet alt_or using (person_id)
join _p_query_lab_tbili_or_gs tbili_or using (person_id)
join _p_query_lab_aof aof using (person_id)
;

create view qc_match_query_lab as
with tmp as (
    select attribute_name, attribute_value, match
    , count(distinct person_id)
    from _p_a_query_lab
    join crit_attribute_used using (attribute_id)
    group by attribute_name, attribute_value, match
)
select attribute_name, attribute_value
, sum(case when match is True then count end) patients_true
, sum(case when match is False then count end) patients_false
, sum(case when match is Null then count end) patients_null
from tmp
group by attribute_name, attribute_value
order by attribute_name, attribute_value
;
select * from qc_match_query_lab;
