--set search_path=ct_${cancer_type};
/***
* lot: including mrn deduplicate
*/
drop table if exists lot;
drop table if exists latest_lot_drug;

create temporary table _line_of_therapy as
    select *
    from demo
    join cplus_from_aplus.person_mrns using (person_id)
    join dev_patient_clinical_${cancer_type}.line_of_therapy using (mrn)
;

create table lot as
select person_id
, max(nvl(lot,0)) n_lot
from demo
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
select count(distinct person_id) from lot where n_lot>0; --v1: 1057 ; v2:1185
-- v3:648
select n_lot, count(distinct person_id)
from lot
group by n_lot
order by n_lot
;

select distinct drug_name from latest_lot_drug;
--person_lot_drug_cats mv to attribute_matching.sql;
*/

