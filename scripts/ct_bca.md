# repopulate the ct_crc schema
* alterations later
* set search_path to psql_w_envs??
```
export cancer_type=BCA
export cancer_type_icd="^(C50|17[45])"
psql -c "create schema if not exists ct_${cancer_type}"
psql_w_envs cancer/prepare_patients.sql
psql_w_envs caregiver/icd_physician.sql
psql_w_envs cancer/prepare_stage.sql
psql_w_envs cancer/prepare_histology.sql
psql_w_envs cancer/prepare_vital.sql #! divide by zero error
psql_w_envs cancer/prepare_lot.sql #! Invalid operation: schema "dev_patient_clinical_bca" does not exist

psql -c "set search_path=ct_${cancer_type}; create or replace view cohort as select distinct person_id from demo"
psql_w_envs caregiver/icd_physician.sql

#later cancer/perpare_alterations.sql
```
