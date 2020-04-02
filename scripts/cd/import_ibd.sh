# the workflow to create and populate ct_${cancer} schema
# requires:
# ct.py_contains, .ref_drug_mapping .ref_lab_mapping
# ct.ref_proc_mapping, ct.ref_rx_mapping

####
# need run config file here 
# source cd/config.sh
# source uc/config.sh

export db_conn=rdmsdw
source util/util.sh
pgsetup ${db_connection}
psql -c "create schema if not exists ${working_schema}"

# prepare references
#cd ${working_dir}
#load_into_db_schema_some_csvs.py rdmsdw ct ref_proc_mapping_20200325.csv
#load_into_db_schema_some_csvs.py rdmsdw ct ref_rx_mapping_20200325.csv
#cd -
psql_w_envs disease/prepare_reference.sql

# prepare attribute
ipython cd/load_attribute.ipy
psql_w_envs cancer/prepare_attribute.sql

# prepare patient data
psql_w_envs disease/prepare_cohort.sql
psql_w_envs disease/prepare_demo_plus.sql
psql_w_envs disease/prepare_diagnosis.sql
psql_w_envs disease/prepare_vital.sql
#psql_w_envs disease/prepare_sochx.sql
psql_w_envs disease/prepare_procedure.sql
psql_w_envs disease/prepare_medication.sql
psql_w_envs disease/prepare_lab.sql
#psql_w_envs caregiver/icd_physician.sql


# perform the attribute matching
psql_w_envs disease/match_rxnorm.sql #> _p_a_t_rxnorm
psql_w_envs disease/match_loinc.sql #> _p_a_t_loinc
psql_w_envs cancer/match_aof20200327.sql #> _p_a_t_aof
psql_w_envs disease/match_diagnosis.sql #> _p_a_t_diagnosis
psql_w_envs disease/match_procedure.sql #> _p_a_t_procedure
psql_w_envs cd/prepare_misc_measurement.sql
psql_w_envs cancer/match_misc_measurement.sql #> _p_a_t_misc_measurement

# compile the matches
psql_w_envs cd/master_match.sql  #> master_match
psql_w_envs disease/master_sheet.sql  #> master_sheet
psql_w_envs disease/master_sheet_mapping.sql

# match to patients
psql_w_envs disease/master_patient.sql #> trial2patients


cd "${working_dir}"
source cancer/download_master_sheet.sh

# deliver master_sheet
source cancer/deliver_master_sheet.sh
cd ${script_dir}
export logic_cols='logic_l1, logic_l2'
mysql_w_envs disease/expand_master_sheet.sql
