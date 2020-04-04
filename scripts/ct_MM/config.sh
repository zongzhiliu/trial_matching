export cancer_type="MM"
export cancer_type_icd="^(C90|230)"
export working_schema="ct_${cancer_type}"
export last_visit_within=99 #years
export protocal_date=$(date +%Y-%m-%d)

export ref_drug_mapping=ct.drug_mapping_cat_expn3_20200308
export ref_lab_mapping=ct.ref_lab_loinc_mapping

export working_dir="$HOME/OneDrive - Sema4 Genomics/rimsdw/${cancer_type}"
export script_dir="$HOME/git/trial_matching/scripts"
