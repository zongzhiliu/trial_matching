export cancer_type=LCA
export cancer_type_icd="^(C34|162)"
export last_visit_within=99 #years
export protocal_date=$(date +%Y-%m-%d)

#export ref_drug_mapping=ct.drug_mapping_cat_expn4_20200313
export ref_drug_mapping=ct.drug_mapping_cat_expn5_20200317
export ref_lab_mapping=ct.ref_lab_loinc_mapping

export working_schema="ct_${cancer_type}"
export working_dir="$HOME/Sema4/rimsdw/${cancer_type}"
export script_dir="$HOME/git/trial_matching/scripts"
