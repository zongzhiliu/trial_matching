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

