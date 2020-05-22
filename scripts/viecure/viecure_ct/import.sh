export db_conn=viecure
export working_schema=ct
export working_dir=$HOME/Sema4/viecure/ct
source util/util.sh
pgsetup viecure
# cohort, demo, histology, stage
psql_w_envs gen_demo.sql

psql_w_envs viecure/viecure_ct/gen_cancer_dx.sql

psql_w_envs viecure/viecure_ct/gen_tests.sql
psql_w_envs viecure/viecure_ct/gen_rx.sql
psql_w_envs viecure/viecure_ct/gen_others.sql
psql_w_envs viecure/viecure_ct/rx_drug.sql
psql_w_envs viecure/viecure_ct/gen_assessment.sql
