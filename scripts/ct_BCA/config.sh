export cancer_type=BCA
export cancer_type_icd="^(C50|17[45])"
export db_conn=rimsdw
export working_schema="ct_${cancer_type}"
export working_dir="$HOME/Sema4/${db_conn}/${working_schema}"

export last_visit_within=99 #years
export protocal_date=$(date +%Y-%m-%d)

#export ref_drug_mapping=ct.drug_mapping_cat_expn4_20200313
export ref_drug_mapping=ct.drug_mapping_cat_expn5_20200317
export ref_lab_mapping=ct.ref_lab_loinc_mapping

