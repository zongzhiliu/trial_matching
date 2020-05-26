set search_path=prod_msdw;
select * from d_metadata
where META_DATA_KEY in (3490, 5719)
-- EPIC: Diagnosis: Encounter Diagnosis: Dx_Annotation
-- EPIC: Problem List: Problem: Comments
;

drop table dx;
create temporary table dx as
    select medical_record_number mrn
    , context_diagnosis_code icd, calendar_date as dx_date
    from d_person
    join fact using(person_key)
    join d_calendar using (calendar_key)
    join b_diagnosis using (diagnosis_group_key)
    join v_diagnosis_control_ref using (diagnosis_key)
    where person_key>3 and context_name like 'ICD%'
        and context_diagnosis_code ~'^(C91[.]?1|204[.]?1)'
;

select icd
    , count(*) records, count(distinct mrn) patients
from dx
group by icd
order by icd
;
select 'total'
    , count(*) records, count(distinct mrn) patients
from dx
;

drop table rx;
create temporary table rx as (
    select medical_record_number mrn
    , nvl(material_name, '_')+'| '+nvl(generic_name, '_')+'| '+nvl(brand1, '_')+'| '+nvl(brand2, '_') as material_title
    from  d_person
    join fact using(person_key)
    join b_material using (material_group_key)
    join v_material_control_ref using (material_key)
    --where lower(material_title) ~ '(^|\\W)(ibrutinib|pci-32765|cra-032765|imbruvica|ibrutix|acalabrutinib)(\\W|$)'
    where person_key>3 and material_key>3
        and lower(material_title) ~ '(^|\\W)(ibrutinib|pci-32765|cra-032765|imbruvica|ibrutix|acalabrutinib|calquence)(\\W|$)'
);

select material_title
, count(*) records, count(distinct mrn) patients
from rx
group by material_title
order by material_title
;

select count(*) records, count(distinct mrn) patients
from rx;

drop table latest_dx;
create temporary table latest_dx as (
    select mrn, icd, dx_date
    , case when icd ~ '0$' then 'no_remission'
        when icd ~ '12$' then 'refactory'
        when icd ~ '[.1]11$' then 'remission'
        end latest_status
    from (select *, row_number() over (
            partition by mrn, icd
            order by dx_date, icd)
        from dx)
    where row_number=1
);

select latest_status, count(*) records, count(distinct mrn) patients
from latest_dx join (select distinct mrn from rx) using (mrn)
-- from latest_dx
group by latest_status --icd
order by latest_status --icd
;
select 'total'
, count(*) records, count(distinct mrn) patients
from latest_dx join rx using (mrn)
;

-- mrns
select distinct mrn from latest_dx join rx using (mrn)
except
select * from  auto_outcome_lca_v3.tmp_cll_388_pts
;

    select diagnosis_role, diagnosis_rank, diagnosis_weighting_factor
    , count(*), count(distinct medical_record_number) patients
    from d_person
    join fact using(person_key)
    join b_diagnosis using (diagnosis_group_key)
    join v_diagnosis_control_ref using (diagnosis_key)
    where person_key>3 and context_name like 'ICD%'
        and context_diagnosis_code = 'C9111'
    group by diagnosis_role, diagnosis_rank, diagnosis_weighting_factor
    order by diagnosis_role, diagnosis_rank, diagnosis_weighting_factor
    ;
