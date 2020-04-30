source viecure/ct_LCA/config.sh
source util/util.sh

psql_w_envs viecure/ct_LCA/prepare_cohort.sh
psql_w_envs viecure/ct_LCA/prepare_demo.sh
psql_w_envs ct_LCA/prepare_diagnosis.sh
psql_w_envs cancer/prepare_variant.sh

