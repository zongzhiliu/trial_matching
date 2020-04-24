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
############################################################ next
#psql_w_envs cancer/match_attributes.sql #>_pa_stage/ecog/karnofsky/lot
psql_w_envs cancer/match_attributes__stage.sql #>_pa_stage
psql_w_envs cancer/match_attributes__performance.sql #>_pa_ecog/karnofsky
psql_w_envs cancer/match_attributes__age.sql #> pat_age
psql_w_envs cancer/match_attributes__vital.sql #> pat_weight/bloodpressure
psql_w_envs cancer/match_attributes__disease.sql #> pa_disease
psql_w_envs cancer/match_attributes__drug_therapy.sql #> pa_/chemo/immuno/hormon/targeted
psql_w_envs cancer/match_lab_pa.sql #>pa_lab
psql_w_envs cancer/match_lab_pat.sql #>pat_lab
psql_w_envs ct_PCA/match_attributes.sql  #> pat_gleason, pa_histology
psql_w_envs ct_PCA/quickadd_match_disease_status.sql #> pa_disease_status
psql_w_envs ct_PCA/quickadd_match_PSA.sql #>pat_psa_at_diagnosis

# compile the matches
psql_w_envs ct_PCA/master_match.sql  #> master_match
psql_w_envs ct_PCA/update_attributes.sql #> crit/trial_attribute_updated
psql_w_envs cancer/trial_logic_levels.sql #> trial_logic_levels
psql_w_envs ct_PCA/master_patient.sql #> master_pathient_summary

#psql_w_envs cancer/quickfix_master_sheet_lca_pca.sql
#psql_w_envs ct_PCA/master_sheet.sql  #> master_sheet to be deprecated
psql_w_envs ct_PCA/expand_attributes.sql #> crit_attribute_expanded, master_sheet_expanded
source ct_PCA/download_master_sheet_expanded.sh
source ct_PCA/deliver_master_sheet_expanded.sh

# perform the attribute matching
psql_w_envs cancer/match_variant.sql
psql_w_envs cancer/match_biomarker.sql #later: code_type=cat/num_measurement
#psql_w_envs cancer/match_loinc.sql
psql_w_envs cancer/match_icd.sql #later: make a _p_a table, and a _p_a_t view
psql_w_envs cancer/match_aof20200311.sql #update match_aof.. later
psql_w_envs cancer/match_rxnorm_wo_modality.sql #: check missing later
psql_w_envs bca/prepare_misc_measurement.sql #mv to cancer later
psql_w_envs cancer/match_misc_measurement.sql
psql_w_envs bca/prepare_cat_measurement.sql #menopausal to be cleaned
psql_w_envs bca/match_cat_measurement.sql #mv to cancer later
psql_w_envs cancer/match_icdo_rex.sql
psql_w_envs cancer/match_stage.sql

# compile the matches
psql_w_envs bca/master_match.sql  #> master_match
psql_w_envs cancer/master_sheet.sql  #> master_sheet
# match to patients
psql_w_envs cancer/master_patient.sql #> trial2patients
# python cancer/master_tree.py generate patient counts at each logic branch,
# and dynamic visualization file for each trial.

# download result files for sharing
source cancer/download_master_patient.sh
############################################################## #
############################################################## #
# deliver
psql_w_envs cancer/quickfix_master_sheet_lca_pca.sql

cd ${working_dir}
source cancer/download_master_sheet.sh
source cancer/deliver_master_sheet.sh

export logic_cols='logic_l1_id'
export disease=${cancer_type}
cd ${script_dir}
mysql_w_envs disease/expand_master_sheet.sql
