###
# config and setup
source mm/config.sh
source util/util.sh
psql -c "create schema if not exists ${working_schema}"

# prepare attribute
ipython mm/load_attribute.py
psql_w_envs cancer/prepare_attribute.sql

# load updated drug/lab mapping table
#no run: load_into_db_schema_some_csvs.py rimsdw ct drug_mapping_cat_expn3_20200308.csv

# prepare patient data
#psql_w_envs cancer/prepare_patients.sql
psql_w_envs cancer/prepare_cohort.sql
psql_w_envs cancer/prepare_diagnosis.sql
psql_w_envs cancer/prepare_performance.sql
psql_w_envs cancer/prepare_lab.sql
psql_w_envs cancer/prepare_lot.sql
psql_w_envs cancer/prepare_vital.sql
psql_w_envs caregiver/icd_physician.sql

# perform the attribute matching
psql_w_envs cancer/match_icd.sql
psql_w_envs cancer/match_loinc.sql
psql_w_envs cancer/match_rxnorm.sql
psql_w_envs cancer/match_misc_measurement.sql

psql_w_envs cancer/match_aof20200229.sql
psql_w_envs mm/match_mm_active_status.sql

# compile the matches
psql_w_envs mm/master_match.sql  #> master_match
psql_w_envs cancer/master_sheet.sql  #> master_sheet

# match to patients (to be updated)
#psql_w_envs cancer/master_patient.sql #> trial2patients

# download result files for sharing
cd "${working_dir}"
select_from_db_schema_table.py rimsdw ${working_schema}.v_master_sheet > v_master_sheet_$(today_stamp).csv
select_from_db_schema_table.py rimsdw ${working_schema}.v_crit_attribute_used > v_crit_attribute_used_$(today_stamp).csv
select_from_db_schema_table.py rimsdw ${working_schema}.v_demo_w_zip > v_demo_w_zip_$(today_stamp).csv
select_from_db_schema_table.py rimsdw ${working_schema}.v_treating_physician > v_treating_physician_$(today_stamp).csv

############################################################## #
cd "${working_dir}"
select_from_db_schema_table.py rimsdw ${working_schema}.v_master_sheet_new > \
    v_master_sheet_new_$(today_stamp).csv
ln -sf v_master_sheet_new_$(today_stamp).csv \
    ${cancer_type}.v_master_sheet_new.csv
load_into_db_schema_some_csvs.py pharma db_data_bridge \
    ${cancer_type}.v_master_sheet_new.csv -d

select_from_db_schema_table.py rimsdw ${working_schema}.v_crit_attribute_used_new > \
    v_crit_attribute_used_new_$(today_stamp).csv
ln -sf v_crit_attribute_used_new_$(today_stamp).csv \
    ${cancer_type}.v_crit_attribute_used_new.csv
load_into_db_schema_some_csvs.py pharma db_data_bridge \
    ${cancer_type}.v_crit_attribute_used_new.csv -d

