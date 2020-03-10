source util/util.sh

psql_w_envs cancer/prepare_patients.sql
psql_w_envs cancer/prepare_lot.sql
psql_w_envs cancer/prepare_vital.sql
psql_w_envs caregiver/icd_physician.sql

# load updated drug mapping table
load_into_db_schema_some_csvs.py rimsdw ct drug_mapping_cat_expn3_20200308.csv
psql_w_envs mm/setup.sql #to be replaced with config file
# load the trial_attribute and crit_attribute using the python sessions below then
psql_w_envs cancer/prepare_attribute.sql
psql_w_envs cancer/match_icd.sql
psql_w_envs cancer/match_loinc.sql
psql_w_envs cancer/match_rxnorm.sql
psql_w_envs cancer/match_misc_measurement.sql
psql_w_envs cancer/match_aof20200229.sql

psql_w_envs mm/match_mm_active_status.sql
psql_w_envs mm/master_match.sql  #> master_match
psql_w_envs cancer/master_sheet.sql  #> master_sheet

# match to patients
psql_w_envs cancer/master_patient.sql #> trial2patients

# download result files for sharing
cd "${working_dir}"
select_from_db_schema_table.py rimsdw ct_mm.v_master_sheet > v_master_sheet_20200310.csv
select_from_db_schema_table.py rimsdw ct_mm.v_crit_attribute_used > v_crit_attribute_used_10100310.csv
select_from_db_schema_table.py rimsdw ct_mm.v_demo_w_zip > v_demo_w_zip_10100310.csv
select_from_db_schema_table.py rimsdw ct_mm.v_treating_physician > v_treating_physician_10100310.csv

