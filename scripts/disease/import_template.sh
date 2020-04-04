############################################################## 
# incomplete do not run
# the workflow to create and populate ct_${cancer} schema
# requires:
# ct.py_contains, reference tables defined in config
# crit_attribute_raw_.csv, trial_attribute_raw_.csv
###
# setup
export db_conn=rdmsdw
export working_schema=ct_AAA
source util/util.sh
source ${working_schema}/config.sh
pgsetup $db_conn
psql -c "create schema if not exists ${working_schema}"
psql_w_envs disease/prepare_reference.sql #share the same code with cancer
###
# prepare attribute
ipython ${working_schema}/load_attribute.ipy
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
#psql_w_envs cancer/match_aof20200327.sql #> _p_a_t_aof
psql_w_envs disease/match_diagnosis.sql #> _p_a_t_diagnosis
psql_w_envs disease/match_procedure.sql #> _p_a_t_procedure
psql_w_envs ${working_schema}/prepare_misc_measurement.sql
psql_w_envs cancer/match_misc_measurement.sql #> _p_a_t_misc_measurement

# compile the matches
psql_w_envs ${working_schema}/master_match.sql  #> master_match
psql_w_envs disease/master_sheet.sql  #> master_sheet
psql_w_envs disease/master_sheet_mapping.sql

# match to patients
psql_w_envs disease/master_patient.sql #> trial2patients

source cancer/download_master_sheet.sh
source cancer/deliver_master_sheet.sh
export logic_cols='logic_l1, logic_l2'
mysql_w_envs disease/expand_master_sheet.sql
