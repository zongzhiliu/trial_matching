# repopulate the ct_mm schema
* stage, histolgy not needed
* alterations later
* icds. labs, etc to limit by last three years?
```
export cancer_type=MM
export cancer_type_icd="^(C90|230)"
psql_w_envs cancer/prepare_patients.sql

psql -c "set search_path=ct_${cancer_type}; create or replace view cohort as select distinct person_id from demo"
psql_w_envs caregiver/icd_physician.sql

#psql mm/setup.sql
#later cancer/perpare_alterations.sql
```
