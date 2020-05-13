/* > _p_lab_query_ast_or_liver
Requires:
    cohort, latest_lab, $ref_lab_mapping
Using: $
References:
*/
drop table if exists _p_query_lab_ast_or_livermet cascade;
create table _p_query_lab_ast_or_livermet as
with como as (
    select person_id
    , bool_or(icd_code ~ '^(C78[.]7|197[.]7)') as livermet
    , bool_or(icd_code ~ '^(E80[.]4|277[.]4)') as gs
    from latest_icd
    group by person_id
), lab as (
    select person_id
    , not bool_or(lab_test_name = 'ALT')
        or bool_or(lab_test_name = 'ALT' and value_float/normal_high<=5) as alt_mid
    , not bool_or(lab_test_name = 'AST')
        or bool_or(lab_test_name = 'AST' and value_float/normal_high<=5) as ast_mid
    , not bool_or(lab_test_name='Total bilirubin')
        or bool_or(lab_test_name='Total bilirubin' and value_float/normal_high <=3) as bili_mid
    from _lab_w_normal_range
    group by person_id
)
select person_id
, ast_mid and nvl(livermet, False) as match
from cohort
left join lab using (person_id)
left join como using (person_id)
;

select match, count(distinct person_id)
from _p_query_lab_ast_or_livermet
group by match
;

