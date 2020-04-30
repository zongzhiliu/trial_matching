#ct
db_conn=viecure
working_schema=ct
working_dir=$HOME/Sema4/viecure/ct
source util/util.sh
load_from_csv drug_mapping_cat_expn6.csv
load_from_csv lca_histology_category.csv
load_from_csv pca_histology_category.csv
load_from_csv ref_lab_loinc_mapping.csv
