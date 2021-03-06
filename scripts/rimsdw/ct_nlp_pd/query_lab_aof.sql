/* > _p_query_lab_aof
Requires:
    latest_lab_mapped, latest_icd
    PLATELETS_MIN
    WBC_MIN
    INR_MAX
References:
<=2.5x ULN AST, ALT (<=5x liver met case)
<=1.5x ULN total bilirubin (<=3x GS case)
1.5x ULN creatinine, >=8 hemoglobin,
>=1,000 cells/uL ANC, >=100,000 platelets,  WBC >=3,000
-- loinc unit of WBC/ANC/plat: x10^3/uL
*/
drop table if exists _p_query_lab_aof cascade;
create table _p_query_lab_aof as
with como as (
    select person_id
    , bool_or(icd_code ~ '^(C78[.]7|197[.]7)') as livermet -- a typo fix here
    , bool_or(icd_code ~ '^(E80[.]4|277[.]4)') as gs
    from latest_icd
    group by person_id
), lab as (
    select person_id
    , not bool_or(lab_test_name in ('ALT', 'AST'))
        or bool_or(lab_test_name in ('ALT', 'AST') and value_float/normal_high <=2.5) as alst_low
    , not bool_or(lab_test_name in ('ALT', 'AST'))
        or bool_or(lab_test_name in ('ALT', 'AST') and value_float/normal_high <=5) as alst_mid
    , not bool_or(lab_test_name='Total bilirubin')
        or bool_or(lab_test_name='Total bilirubin' and value_float/normal_high <=1.5) as bili_low
    , not bool_or(lab_test_name='Total bilirubin')
        or bool_or(lab_test_name='Total bilirubin' and value_float/normal_high <=3) as bili_mid
    , not bool_or(lab_test_name='Serum Creatinine')
        or bool_or(lab_test_name='Serum Creatinine' and value_float/normal_high <=1.5) as crea_ok
    , not bool_or(lab_test_name='Hemoglobin')
        or bool_or(lab_test_name='Hemoglobin' and value_float>=8) as hemo_ok
    , not bool_or(lab_test_name='ANC')
        or bool_or(lab_test_name='ANC' and value_float>=1) as anc_ok  --unit different
    , not bool_or(lab_test_name='Platelets')
        or bool_or(lab_test_name='Platelets' and value_float>=${PLATELETS_MIN}) as plat_ok--unit different
    , not bool_or(lab_test_name='WBC')
        or bool_or(lab_test_name='WBC' and value_float>=${WBC_MIN}) as wbc_ok--unit different
    , not bool_or(lab_test_name='INR')
        or bool_or(lab_test_name='INR' and value_float/normal_high <= ${INR_MAX}) as inr_ok
    from _lab_w_normal_range
    group by person_id
)
select person_id
, (alst_low or alst_mid and nvl(livermet, False))
    and (bili_low or bili_mid and nvl(gs, False))
    and crea_ok
    and hemo_ok and wbc_ok
    and anc_ok and plat_ok
    and inr_ok
    as match
from cohort
left join lab using (person_id)
left join como using (person_id)
;

select match
, count(*) records, count(distinct person_id) patients
from _p_query_lab_aof
group by match;
