#export cancer_histology_cat=nsclc #ref_histology_mapping
export cancer_type=LCA
export cancer_type_icd="^(C34|162)" #use a ref table later

export db_conn=rimsdw
export working_schema=ct_LCA
export working_dir="$HOME/Sema4/${db_conn}/${working_schema}"

export last_visit_within=3 #years
export protocal_date=$(date +%Y-%m-%d)

export trial_attribute=ct.nsclc_trial_attribute_raw_20200223
export crit_attribute=ct.crit_attribute_used_lca_pca_20200424
export crit_attribute_mapping=ct.crit_attribute_used_lca_pca_20200424
export ref_histology_mapping=ct.lca_histology_category

export ref_drug_mapping=ct.drug_mapping_cat_expn6
export ref_lab_mapping=ct.ref_lab_loinc_mapping
#export ref_rx_mapping=ct.ref_rx_mapping_20200325
export ref_cancer_icd=ct.ref_cancer_icd

# AOF value config
export PLATELETS_MIN=100
export WBC_MIN=3
export IRN_MAX=99999
