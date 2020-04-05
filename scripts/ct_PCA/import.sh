############################################################## 
# incomplete do not run
# the workflow to create and populate ct_${cancer} schema
# requires:
# ct.py_contains, .ref_drug_mapping .ref_lab_mapping
### runnable
# setup
source pca/config.sh
source util/util.sh
export db_conn=rimsdw
pgsetup $db_conn
psql -c "create schema if not exists ${working_schema}"
psql_w_envs cancer/prepare_reference.sql
### !! donot run
# prepare attribute
ipython pca/load_attribute.ipy
psql_w_envs cancer/prepare_attribute.sql

### !! donot run
# prepare patient data
psql_w_envs ${working_schema}/quickfix_prepare_drug.sql # drug mapping needed
#psql_w_envs cancer/prepare_vital.sql #! divide by zero error
psql_w_envs cancer/prepare_cohort.sql
psql_w_envs cancer/prepare_diagnosis.sql
psql_w_envs cancer/prepare_performance.sql
psql_w_envs cancer/prepare_lab.sql
psql_w_envs cancer/prepare_lot.sql # drug mapping needed
psql_w_envs cancer/prepare_stage.sql
psql_w_envs cancer/prepare_histology.sql
psql_w_envs cancer/prepare_variant.sql
psql_w_envs cancer/prepare_biomarker.sql
#psql_w_envs caregiver/icd_physician.sql

### !!do not run
# perform the attribute matching
#psql_w_envs cancer/match_loinc.sql
psql_w_envs cancer/match_icd.sql #later: make a _p_a table, and a _p_a_t view
psql_w_envs cancer/match_aof20200311.sql #update match_aof.. later
psql_w_envs cancer/match_rxnorm_wo_modality.sql #: check missing later
psql_w_envs pca/prepare_misc_measurement.sql #mv to cancer later
psql_w_envs cancer/match_misc_measurement.sql
psql_w_envs pca/prepare_cat_measurement.sql #menopausal to be cleaned
psql_w_envs pca/match_cat_measurement.sql #mv to cancer later
psql_w_envs cancer/match_icdo_rex.sql
psql_w_envs cancer/match_stage.sql
psql_w_envs cancer/match_variant.sql
psql_w_envs cancer/match_biomarker.sql #later: code_type=cat/num_measurement

### Runable
# compile the matches
psql_w_envs ct_PCA/master_match.sql  #> master_match
psql_w_envs disease/master_sheet.sql  #> master_sheet
psql_w_envs disease/logic_to_levels.sql
psql_w_envs disease/master_patient.sql #> trial2patients
# python cancer/master_tree.py generate patient counts at each logic branch,
# and dynamic visualization file for each trial.

### Runnable
# download and deliver
ipython cancer/download_master_patient.ipy
psql_w_envs cancer/quickfix_master_sheet_lca_pca.sql
source cancer/download_master_sheet.sh
source cancer/deliver_master_sheet.sh
export logic_cols='logic_l1_id'
export disease=${cancer_type}
mysql_w_envs disease/expand_master_sheet.sql
