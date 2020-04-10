/* impute stage from TNM, PSA, gleason
Required: cohort, cplus_from_aplus
Result: stage_plus, stage
    note that one person can have 2+ stages.
Reference: NCCN guideline
*/

drop table if exists stage_plus cascade;
create table stage_plus as
with cd as (
	select person_id
	, ajcc_clinical_t c_t, ajcc_clinical_n c_n, ajcc_clinical_m c_m
	, ajcc_pathological_t p_t, ajcc_pathological_n p_n, ajcc_pathological_m p_m
	, overall_stage st, gleason_grade gg, psa
	from cohort
	join cplus_from_aplus.cancer_diagnoses using (person_id)
	left join cplus_from_aplus.cancer_diagnoses_pca using (cancer_diagnosis_id)
), converted as (
	select person_id, psa
	, case when st in ('Not Reported', 'Not Applicable')
	    then null else st end st
	, case gg when 'Not Reported' then null else gg::int end gg
	, case when c_t in ('Not Reported', 'Not Applicable', 'Tx')
	    then null else c_t end as c_t
	, case when p_t in ('Not Reported', 'Not Applicable', 'Tx')
	    then null else p_t end as p_t
	, case when c_n in ('Not Reported', 'Not Applicable', 'Nx')
	    then null else c_n end as c_n
	, case when p_n in ('Not Reported', 'Not Applicable', 'Nx')
	    then null else p_n end as p_n
	, case when c_m in ('Not Reported', 'Not Applicable', 'Mx')
	    then null else c_m end as c_m
	, case when p_m in ('Not Reported', 'Not Applicable', 'Mx')
	    then null else p_m end as p_m
	from cd
), imputed as (
    select person_id, st, psa, gg
    , greatest(p_t, c_t) t
    , greatest(p_n, c_n) n
    , greatest(p_m, c_m) m
    , case
        when m like 'M1%' then 'IVB' --M0/x here after
        when n like 'N1%' then 'IVA' --N0/x here after
        when gg=5 then 'IIIC' --gg<5/x here after
        when t ~ '^T[34]' then 'IIIB' --T[12] here after
        when psa >= 20 then 'IIIA' --psa<20/x here after
        when gg>=3 then 'IIC' -- gg<3 here after
        when gg=2 then 'IIB' -- gg1/x here after
        when t ~ '^T2[bc]' or psa>=10 then 'IIA' --psa<10 here after
        when t ~ '^T[12]' then 'I' --T required
        end stage_imputed
    from converted
)
/*
select st stage_extracted, t, n, m, gg, stage_imputed
, listagg(distinct psa::varchar, '| ') within group (order by -psa)
from imputed
group by stage_extracted, t, n, m, gg, stage_imputed
order by stage_imputed desc nulls last, m, n, gg, t
;
*/
select person_id
, st stage_extracted
, stage_imputed
, t, n, m, gg, psa
, nvl(st, stage_imputed) stage
, regexp_substr(stage, '^[IV]+') stage_base
from imputed
;

create view stage as
select * from stage_plus
order by person_id;
