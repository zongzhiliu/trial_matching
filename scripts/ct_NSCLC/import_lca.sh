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
psql_w_envs ct_NSCLC/match_code_icd.sql # > pa_icd
############################################################ next
#load attribute table with code columns
psql_w_envs cancer/match_variant.sql
#psql_w_envs ct_PCA/quickadd_match_disease_status.sql #> pa_disease_status
psql_w_envs cancer/match_rxnorm_wo_modality.sql #: check missing later
psql_w_envs cancer/match_biomarker.sql #later: code_type=cat/num_measurement

# compile the matches
psql_w_envs ct_NSCLC/master_match.sql  #> master_match
psql_w_envs ct_NSCLC/update_attributes.sql #> crit/trial_attribute_updated
psql_w_envs cancer/trial_logic_levels.sql #> trial_logic_levels
psql_w_envs ct_NSCLC/master_patient.sql #> master_pathient_summary

#psql_w_envs cancer/quickfix_master_sheet_lca_pca.sql
#psql_w_envs ct_PCA/master_sheet.sql  #> master_sheet to be deprecated
psql_w_envs ct_NSCLC/expand_attributes.sql #> crit_attribute_expanded, master_sheet_expanded
source ct_NSCLC/download_master_sheet_expanded.sh
source ct_NSCLC/deliver_master_sheet_expanded.sh


