--set search_path=ct_${cancer_type};
/***
* lot: including mrn deduplicate
*/
drop table if exists _line_of_therapy cascade;
drop table if exists lot cascade;
drop table if exists modality_lot cascade;
drop table if exists latest_lot_drug cascade;

create table _line_of_therapy as
    select *
    , drugname drug_name
    from cohort
    join cplus_from_aplus.person_mrns using (person_id)
    join dev_patient_clinical_${cancer_type}.line_of_therapy using (mrn)
;

create table modality_lot as
with m_lot as (
    select person_id, modality
    , count(distinct lot) lot
    from _line_of_therapy
    join ref_drug_mapping using (drug_name)
    group by person_id, modality
)
/*
-- debug
select distinct lot from m_lot;
select modality, count(*)
from m_lot
group by modality ;
--ok
*/
select person_id, modality
, nvl(lot, 0) n_lot
from (cohort
    cross join (select distinct modality from ref_drug_mapping))
left join m_lot using (person_id, modality)
;

create table lot as
select person_id
, max(nvl(lot,0)) n_lot
from cohort
left join _line_of_therapy using (person_id)
group by person_id
;
create table latest_lot_drug as
select person_id, drugname drug_name, max(agedays) as last_ageday
from _line_of_therapy
--where lot>=1
group by person_id, drugname
;
/*qc
select count(distinct person_id) from lot where n_lot>0;
-- 5379
select count(distinct person_id) from modality_lot where n_lot>0;
-- 5365

select modality, count(distinct person_id) patients
from modality_lot
where n_lot>0
group by modality
;
select n_lot, count(distinct person_id)
from lot
group by n_lot
order by n_lot
;

-- debug
with tmp as(
select distinct drug_name from _line_of_therapy
left join ${ref_drug_mapping} using (drug_name)
where modality is null
)
select * 
from resource.all_cancer_drugs_list ac
--from ${ref_drug_mapping}
join tmp on lower(ac.drug_name)=tmp.drug_name
;
*/

