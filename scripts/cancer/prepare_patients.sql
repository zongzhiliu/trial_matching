/***
Requires:
    prod_msdw.all_labs
    prod_references
    dev_patient_info_${cancer_type}
    dev_patient_clinical_${cancer_type}
Results:
    demo
    loh, latest_lot_drug
    latest_icd, latest_lab
    latest_ecog, latest_karnofsky
    vital, vital_bmi
Setttings:
    @set cancer_type=
*/
-- icds. labs, etc to limit by last three years?
-- set search_path=ct_${cancer_type};


/***
* cancer_dx using {cancer_type}
* demo, stage, histology
, gleason, psa
*/

/***
* lot: including mrn deduplicate
*/

/*** later: use lot from cplus
create table line_of_therapy as
select person_id
, drug_generic_name as drugname
, to_date(year_of_medication || '-' || month_of_medication || '-' || day_of_medication, 'YYYY-MM-DD') as drug_date
, line_of_therapy as lot
select count(distinct person_id)
from demo
join cplus_from_aplus.medications m using (person_id)
join cplus_from_aplus.line_of_therapies l using (medication_id) --2223
--join cplus_from_aplus.cancer_drugs using (drug_id, cancer_type_id)  -- only 65 upto here, stop ask for help later.
join cplus_from_aplus.drugs using (drug_id) --2223
join cplus_from_aplus.cancer_types using (cancer_type_id)
where cancer_type_name='PCA'  --2029
    and nvl(m.status, '')!='deleted' and nvl(l.status, '')!='deleted'
;

select distinct status from cplus_from_aplus.line_of_therapies;
select distinct status from cplus_from_aplus.medications;
select count(distinct person_id) from line_of_therapy;  --1615
--drop table line_of_therapy;
*/


