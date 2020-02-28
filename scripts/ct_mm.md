# repopulate the ct_mm schema
* stage, histolgy not needed
* alterations later
* icds. labs, etc to limit by last three years?
```
function psql_w_envs {
    cat $1 | substitute_env_vars_in_pipe.py \
    | psql --echo-all --no-psqlrc -v ON_ERROR_STOP=1
}
export cancer_type=MM
export cancer_type_icd="^(C90|230)"
psql_w_envs cancer/prepare_patients.sql
#psql mm/setup.sql
#later cancer/perpare_alterations.sql
```
