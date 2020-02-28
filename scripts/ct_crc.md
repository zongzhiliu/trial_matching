# repopulate the ct_crc schema
* alterations later
* set search_path to psql_w_envs??
```
function psql_w_envs {
    cat $1 | substitute_env_vars_in_pipe.py \
    | psql --echo-all --no-psqlrc -v ON_ERROR_STOP=1
}
export cancer_type=CRC
export cancer_type_icd="^(15[34]|C(20|1[89]))"
psql -c "create schema if not exists ct_${cancer_type}"
psql_w_envs cancer/prepare_patients.sql
psql_w_envs cancer/prepare_stage.sql
psql_w_envs cancer/prepare_histology.sql
#later cancer/perpare_alterations.sql
```
