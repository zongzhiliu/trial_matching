/***
* lot: including mrn deduplicate
Requires: cohort, ref_drug_mapping, cplus, dev_patient_clinical
Results: lot, modality_lot, latest_lot_drug
*/
drop table if exists _line_of_therapy cascade;
create table _line_of_therapy as
    select *
    , drugname drug_name
    from cohort
    join cplus_from_aplus.person_mrns using (person_id)
    join dev_patient_clinical_${cancer_type}.line_of_therapy using (mrn)
;

drop table if exists modality_lot cascade;
create table modality_lot as
with m_lot as (
    select person_id, modality
    , count(distinct lot) lot
    from _line_of_therapy
    join ref_drug_mapping using (drug_name)
    group by person_id, modality
)
select person_id, modality
, nvl(lot, 0) n_lot
from (cohort
    cross join (select distinct modality from ref_drug_mapping))
left join m_lot using (person_id, modality)
;

drop table if exists lot cascade;
create table lot as
select person_id
, max(nvl(lot,0)) n_lot
from cohort
left join _line_of_therapy using (person_id)
group by person_id
;

drop table if exists latest_lot_drug cascade;
create table latest_lot_drug as
select person_id, drugname drug_name, max(agedays) as last_ageday
from _line_of_therapy
--where lot>=1
group by person_id, drugname
;

create view qc_lot as
select n_lot, count(distinct person_id) patients
from lot
group by n_lot
order by n_lot
;
select count(distinct person_id) from lot where n_lot > 0;
