export db_conn=viecure
export working_schema=viecure_ct
export working_dir=$HOME/Sema4/viecure/viecure_ct
source util/util.sh
pgsetup viecure
# cohort, demo, histology, stage
psql_w_envs gen_demo.sql
psql_w_envs viecure/viecure_ct/gen_cancer_dx.sql
psql_w_envs viecure/viecure_ct/gen_tests.sql
psql_w_envs viecure/viecure_ct/gen_latest_test.sql
psql_w_envs viecure/viecure_ct/gen_rx.sql
#psql_w_envs viecure/viecure_ct/gen_others.sql
psql_w_envs viecure/viecure_ct/gen_tumor_marker.sql
psql_w_envs viecure/viecure_ct/gen_gene_alteration.sql
psql_w_envs viecure/viecure_ct/rx_drug.sql
psql_w_envs viecure/viecure_ct/gen_assessment.sql
