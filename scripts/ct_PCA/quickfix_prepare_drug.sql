-- using dev_patient_info.medications
drop table if exists _drug;
create table _drug as
with rx as (
    select distinct medical_record_number mrn
    , lower(rx_generic) rx_generic, lower(rx_name) rx_name
    from dev_patient_info_pca.medications
    where rx_generic is not null
)
select person_id, drug_name, rx_name, rx_generic, modality, moa
from rx
join prod_references.person_mrns using (mrn)
join ct.drug_mapping_cat_expn6 dm
    on rx_generic like drug_name||'%' or rx_name like drug_name||'%'
;



