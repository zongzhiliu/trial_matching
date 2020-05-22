#ct
export db_conn=viecure
export working_schema=ct
export working_dir=$HOME/Sema4/viecure/ct
source util/util.sh
pgsetup viecure
## viecure/ct/setup.md

psql_w_envs ct/udf.sql  #error: $$ -> $
load_from_csv drug_mapping_cat_expn6.csv
load_from_csv lca_histology_category.csv
load_from_csv pca_histology_category.csv
load_from_csv ref_test_loinc.csv
load_from_csv ref_test.csv
psql_w_envs viecure/ct/quickfix.sql
psql_w_envs viecure/ct/qc.sql
#############################################################next
load_from_csv ref_disease_icd
psql_w_envs viecure/ct/drug_alias.sql

