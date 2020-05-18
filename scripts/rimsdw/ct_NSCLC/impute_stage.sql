/* impute stage from TNM
Required: cancer_dx
Result: stage_plus
    note that one person can have 2+ stages.
Reference: NCCN guideline
*/

drop table if exists stage_plus cascade;
create table stage_plus as
with cdx as (
    select cancer_diagnosis_id
    , person_id
    , c_t, c_n, c_m, p_t, p_n, p_m
    , case stage_extracted != 'Occult Carcinoma'
        then stage_extracted else '00' end stage_extracted
    from cancer_dx
), imputed as (
    select cancer_diagnosis_id
    , nvl(p_t, c_t) t
    , nvl(p_n, c_n) n
    , nvl(p_m, c_m) m
    , case
        when m ilike 'M1c%' then 'IVB'
        when m like 'M1%' then 'IVA'
        when n like 'N3%' then
            case when t ~ '^(T[34])' then 'IIIC' else 'IIIB' end
        when n like 'N2%' then
            case when t ~ '^(T[34])' then 'IIIB' else 'IIIA' end
        when n like 'N%' then
            case when t ~ '^(T[34])' then 'IIIA' else 'IIB' end
        when t like 'T4%' then 'IIIA'
        when t like 'T3%' then 'IIB'
        when t ilike 'T2b%' then 'IIA'
        when t like 'T2%' then 'IB'
        when t like 'T1%' then 'IA'
        when t ilike 'Tis%' then '0'
        when t ilike 'Tx%' then 'Occult Carcinoma'
        end stage_imputed
    from cdx
)
select cancer_diagnosis_id, person_id
, stage_imputed, t, n, m
, stage_extracted
, nvl(c_t, 'T_')+nvl(c_n, 'N_')+nvl(c_m, 'M_') ctnm
, nvl(p_t, 'T_')+nvl(p_n, 'N_')+nvl(p_m, 'M_') ptnm
, nvl(stage_extracted, stage_imputed) stage
from imputed
join cdx using (cancer_diagnosis_id)
;

create view qc_stage_plus as
select stage_imputed, t, n, m, sp.stage_extracted, ctnm, ptnm
, count(*) records, count(distinct sp.person_id) patients
from stage_plus sp join cancer_dx using (cancer_diagnosis_id)
group by stage_imputed, t, n, m, sp.stage_extracted, ctnm, ptnm
order by stage_imputed desc nulls last, m, n, t
;
select * from qc_stage_plus;

select ct.assert (bool_and(stage like '0%' or stage like 'I%')
, 'stage startswith 0 or I') from stage_plus
;

with a as (
    select count(*) from stage_plus where stage is not null
), e as (
    select count(*) from stage_plus where stage_extracted is not null
)
select a.count, e.count, ct.assert(a.count>e.count, 'imputing rescues some stage')
from a cross join e
;

