export db_conn=rdmsdw
export disease=PH1
export disease_icd="^(E72[.]?53|271[.]?8)"
export working_schema="ct_${disease}"
export last_visit_within=99 #years
export protocal_date=$(date +%Y-%m-%d)

export dmsdw=dmsdw_2019q1
export ref_drug_mapping=ct.drug_mapping_cat_expn6
export ref_lab_mapping=ct.ref_lab_loinc_mapping
export ref_proc_mapping=ct.ref_proc_mapping_20200325
export ref_rx_mapping=ct.ref_rx_mapping_20200325

export working_dir="$HOME/Sema4/${db_conn}/${working_dir}"
