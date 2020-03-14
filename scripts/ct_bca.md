# repopulate the ct_bca schema
* alterations later
* set search_path to psql_w_envs??
```
psql -c "create schema if not exists ct_${cancer_type}"
```
