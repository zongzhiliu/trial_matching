###
# config and setup
source rimsdw/ct_MM/config.sh
pgsetup $db_conn
source util/util.sh
psql -c "create schema if not exists ${working_schema}"

# prepare attribute
# ipython ct_MM/load_attribute.py
psql_w_envs rimsdw/ct_MM/setup.sql
psql_w_envs cancer/prepare_attribute.sql

# prepare patient data
psql_w_envs cancer/prepare_cohort.sql
psql_w_envs cancer/prepare_demo.sql
psql_w_envs cancer/prepare_histology.sql
psql_w_envs cancer/prepare_stage.sql
psql_w_envs cancer/prepare_diagnosis.sql
psql_w_envs cancer/prepare_performance.sql
psql_w_envs cancer/prepare_lab.sql
psql_w_envs cancer/prepare_lot.sql
psql_w_envs cancer/prepare_vital.sql
psql_w_envs cancer/prepare_variant.sql
psql_w_envs cancer/prepare_biomarker.sql
psql_w_envs disease/prepare_procedure.sql
#psql_w_envs caregiver/icd_physician.sql

# perform the attribute matching
psql_w_envs cancer/match_icd.sql
psql_w_envs cancer/match_loinc.sql
psql_w_envs cancer/match_rxnorm.sql
psql_w_envs cancer/match_misc_measurement.sql

psql_w_envs cancer/match_aof20200229.sql
psql_w_envs rimsdw/ct_MM/match_mm_active_status.sql
psql_w_envs rimsdw/ct_MM/match_cancer_dx_mm.sql
psql_w_encs rimsdw/ct_MM/match_query_translocation.sql

# compile the matches
psql_w_envs mm/master_match.sql  #> master_match
psql_w_envs cancer/master_sheet.sql  #> master_sheet

# match to patients (to be updated)
#psql_w_envs cancer/master_patient.sql #> trial2patients

# download result files for sharing
cd "${working_dir}"
# source cancer/download_master_patient.sh
# deliver
source cancer/download_master_sheet.sh
source cancer/deliver_master_sheet.sh

cd ${script_dir}
export logic_cols='logic_l1_id'
export disease=${cancer_type}
mysql_w_envs disease/expand_master_sheet.sql
