export disease=CD
export disease_icd="^(K50|555[.][0-1])"
export working_schema="ct_${disease}"
export last_visit_within=99 #years

export dmsdw=dmsdw_2019q1
export ref_drug_mapping=ct.drug_mapping_cat_expn5_20200317
export ref_lab_mapping=ct.ref_lab_loinc_mapping

export working_dir="$HOME/Sema4/rdmsdw/${disease}"
export script_dir="$HOME/git/trial_matching/scripts"
