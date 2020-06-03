# import the ct schema

## UDFs
ct/udf.sql

## mapping table
### drug mapping expn5
    * fix: invalid character between 'synthesis inhibitor'
    * remove: redundate rows, redundate MOA items, empty MOA items ('||')
    * fix unnormalized drug names irinotican (Iriotican), unnormalized modality ('Hormone therapy', 'Chemotherapy')
    * fix extraspaces between drug_name, moa items
    * load and transform
```
psql -c 'drop table if exists ct.drug_mapping_cat_expn5_20200317 cascade'
load_into_db_schema_some_csvs.py rimsdw ct drug_mapping_cat_expn5_20200317.csv
```

* 20200603 update
```
create table ct.mm_trial_attribute as select * from ct_mm.trial_attribute_raw;
create table ct.mm_crit_attribute as select * from ct_mm.crit_attribute_raw;
create table ct.mm_crit_attribute_mapping as select * from ct_mm.crit_attribute_mapping_raw;
```
