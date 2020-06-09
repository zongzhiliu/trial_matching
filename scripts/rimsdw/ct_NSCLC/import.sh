source util/util.sh
source rimsdw/ct_NSCLC/config.sh
source rimsdw/setup.sh
psql_w_envs rimsdw/ct_NSCLC/setup.sql

psql_w_envs cancer/prepare_cohort.sql
psql_w_envs cancer/prepare_histology.sql
# subset the cohort with histology: NSCLC
psql_w_envs rimsdw/ct_NSCLC/update_cohort_histology.sql

# complement the stage with imputed ones
psql_w_envs cancer/prepare_cancer_dx.sql #> cancer_dx
psql_w_envs rimsdw/ct_NSCLC/impute_stage.sql #> stage_plus
psql_w_envs rimsdw/ct_NSCLC/prepare_stage.sql #> latest_stage

source rimsdw/ct_NSCLC/import_lca.sh
