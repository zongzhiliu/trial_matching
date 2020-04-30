source viecure/ct_LCA/config.sh
source util/util.sh
pgsetup $db_conn

psql_w_envs viecure/ct_LCA/prepare_cohort.sh
psql_w_envs viecure/ct_LCA/prepare_demo.sh
psql_w_envs cancer/prepare_variant.sh

