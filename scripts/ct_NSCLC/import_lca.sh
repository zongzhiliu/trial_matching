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


# perform the attribute matching
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
psql_w_envs cancer/match_variant.sql
psql_w_envs cancer/match_biomarker.sql #later: code_type=cat/num_measurement

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
