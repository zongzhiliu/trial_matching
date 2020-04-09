export cancer_type=PCA
export cancer_type_icd='^(C61|185)'
####export cancer_type_icd="^(C50|17[45])"
export working_schema="ct_${cancer_type}"
export last_visit_within=99 #years
export protocal_date=$(date +%Y-%m-%d)

#export ref_drug_mapping=ct.drug_mapping_cat_expn4_20200313
export ref_drug_mapping=ct.drug_mapping_cat_expn6
export ref_lab_mapping=ct.ref_lab_loinc_mapping

export working_dir="$HOME/Sema4/rimsdw/${working_schema}"
export script_dir="$HOME/git/trial_matching/scripts"
