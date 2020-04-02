export cancer_type='PCA'
export logic_cols='logic_l1'
psql_w_envs tests/test_psql_w_envs.sql

export logic_cols='logic_l1, logic_l2'
psql_w_envs tests/test_psql_w_envs.sql
