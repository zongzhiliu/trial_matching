############################################################## 
# incomplete do not run
# the workflow to create and populate ct_${cancer} schema
# requires:
# ct.py_contains, .ref_drug_mapping .ref_lab_mapping
###
# source ct_NSCLC/config.sh
# source ct_SCLC/config.sh
# prepare patient data
psql_w_envs cancer/prepare_demo.sql
psql_w_envs cancer/prepare_diagnosis.sql
psql_w_envs cancer/prepare_performance.sql
psql_w_envs cancer/prepare_lab.sql
psql_w_envs cancer/prepare_vital.sql
psql_w_envs cancer/prepare_lot.sql
psql_w_envs cancer/prepare_variant.sql
psql_w_envs cancer/prepare_biomarker.sql
#psql_w_envs caregiver/icd_physician.sql

# match to attributes
psql_w_envs cancer/match_attributes__stage.sql #>_pa_stage
psql_w_envs cancer/match_attributes__performance.sql #>_pa_ecog/karnofsky
psql_w_envs cancer/match_attributes__lot.sql #>_pa_lot
psql_w_envs cancer/match_attributes__age.sql #> pat_age
psql_w_envs cancer/match_attributes__vital.sql #> pat_weight/bloodpressure
psql_w_envs cancer/match_lab_pa.sql #>pa_lab
psql_w_envs ct_NSCLC/match_attributes__histology.sql  #> pa_histology
#load attribute table with code columns
psql_w_envs rimsdw/ct_NSCLC/match_code_icd.sql # > pa_icd_rex
psql_w_envs rimsdw/ct_NSCLC/match_code_variant.sql #> pa_variant
psql_w_envs rimsdw/ct_NSCLC/match_code_biomarker.sql #> pa_biomarker
psql_w_envs rimsdw/ct_NSCLC/match_code_drug.sql #> pa_drug
# compile the matches
psql_w_envs rimsdw/ct_NSCLC/master_match.sql  #> master_match
psql_w_envs rimsdw/ct_NSCLC/update_attributes.sql #> crit/trial_attribute_updated
psql_w_envs cancer/trial_logic_levels.sql #> trial_logic_levels
psql_w_envs rimsdw/ct_PCA/master_patient.sql #> master_pathient_summary
export_w_today master_patient_summary
# deliver
export_w_today v_demo_w_zip
load_to_pharma v_demo_w_zip
psql_w_envs rimsdw/ct_NSCLC/expand_attributes.sql #> crit_attribute_expanded, master_sheet_expanded
export_w_today qc_attribute_match_summary
export_w_today v_crit_attribute_expanded
load_to_pharma v_crit_attribute_expanded
export_w_today v_master_sheet_expanded
load_to_pharma v_master_sheet_expanded
############################################################ next


