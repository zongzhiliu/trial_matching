#ct
export db_conn=viecure
export working_schema=ct
export working_dir=$HOME/Sema4/viecure/ct
source util/util.sh
pgsetup viecure

psql_w_envs ct/udf.sql  #error: $$ -> $
load_from_csv drug_mapping_cat_expn6.csv
load_from_csv lca_histology_category.csv
load_from_csv pca_histology_category.csv
load_from_csv ref_lab_loinc_mapping.csv


