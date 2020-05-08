source rimsdw/ct_NSCLC/config.sh
source util/util.sh
pgsetup $db_conn
psql -c "create schema if not exists ${working_schema}"
psql_w_envs rimsdw/ct_NSCLC/setup.sql

psql_w_envs cancer/prepare_cohort.sql
psql_w_envs cancer/prepare_histology.sql
# subset the cohort with histology: NSCLC
psql_w_envs rimsdw/ct_NSCLC/update_cohort_histology.sql

# complement the stage with imputed ones
psql_w_envs rimsdw/ct_NSCLC/update_stage.sql

source rimsdw/ct_NSCLC/import_lca.sh
