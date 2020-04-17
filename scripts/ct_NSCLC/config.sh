############################################################## #
# do not run
export cancer_type=NSCLC
export cancer_type_icd="^(C34|162)"
export db_conn=rimsdw
export working_schema="ct_${cancer_type}"
export working_dir="$HOME/Sema4/${db_conn}/${working_schema}"
export last_visit_within=99 #years
export protocal_date=$(date +%Y-%m-%d)

export ref_drug_mapping=ct.drug_mapping_cat_expn6
export ref_lab_mapping=ct.ref_lab_loinc_mapping
export ref_proc_mapping=ct.ref_proc_mapping_20200325
export ref_rx_mapping=ct.ref_rx_mapping_20200325
#export ref_drug_mapping=ct.drug_mapping_cat_expn5_20200317

# AOF value config
export PLATELETS_MIN=100
export WBC_MIN=3
export IRN_MAX=99999
