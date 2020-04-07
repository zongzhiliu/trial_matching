export disease=UC
export disease_icd="^(K51|556[.][2-6])"

export db_conn=rdmsdw
export dmsdw=dmsdw_testing
export working_schema="ct_UC_testing"
export working_dir="$HOME/Sema4/${db_conn}/${working_schema}"

export last_visit_within=99 #years
export protocal_date=$(date +%Y-%m-%d)

export ref_drug_mapping=ct.drug_mapping_cat_expn6
export ref_lab_mapping=ct.ref_lab_loinc_mapping
export ref_proc_mapping=ct.ref_proc_mapping_20200325
export ref_rx_mapping=ct.ref_rx_mapping_20200325
