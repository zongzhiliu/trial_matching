# repopulate the ct_crc schema
* alterations later
* set search_path to psql_w_envs??
```
export cancer_type=CRC
export cancer_type_icd="^(15[34]|C(20|1[89]))"
psql -c "create schema if not exists ct_${cancer_type}"
psql_w_envs cancer/prepare_patients.sql
psql_w_envs cancer/prepare_stage.sql
psql_w_envs cancer/prepare_histology.sql

psql -c "set search_path=ct_${cancer_type}; create or replace view cohort as select distinct person_id from demo"
psql_w_envs caregiver/icd_physician.sql

#later cancer/perpare_alterations.sql
```
