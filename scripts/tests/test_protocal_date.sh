export protocal_date=$(date +%Y-%m-%d)
psql_w_envs tests/test_protocal_date.sql

export protocal_date=2020-07-01
psql_w_envs tests/test_protocal_date.sql
