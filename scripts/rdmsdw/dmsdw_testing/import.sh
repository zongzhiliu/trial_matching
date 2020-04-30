pgsetup rdmsdw
working_schema='dmsdw_testing';
psql -c "create schema if not exists ${working_schema}"
psql_w_envs dmsdw_testing/genrate_1_perc.sql
