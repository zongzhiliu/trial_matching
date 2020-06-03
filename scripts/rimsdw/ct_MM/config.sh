export cancer_type="MM"
export cancer_type_icd="^(C90|230)"
export db_conn=rimsdw
export working_schema="ct_${cancer_type}"
export working_dir="$HOME/Sema4/${db_conn}/${working_schema}"

export last_visit_within=99 #years
export protocal_date=$(date +%Y-%m-%d)

export trial_attribute=ct.mm_trial_attribute
export crit_attribute=ct.mm_crit_attribute
export crit_attribute_mapping=ct.mm_crit_attribute_mapping
#export ref_histology_mapping=ct.lca_histology_category

export ref_drug_mapping=ct.drug_mapping_cat_expn9
export ref_lab_mapping=ct.ref_lab_loinc_mapping
#export ref_proc_mapping=ct.ref_proc_mapping_20200325
#export ref_rx_mapping=ct.ref_rx_mapping_20200325


