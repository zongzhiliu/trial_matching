# the workflow to create and populate ct_${cancer} schema
# requires:
# ct.py_contains, .ref_drug_mapping .ref_lab_mapping
source bca/config.sh
source util/util.sh
psql -c "create schema if not exists ${working_schema}"
psql_w_envs cancer/prepare_reference.sql

# prepare patient data
psql_w_envs cancer/prepare_cohort.sql
psql_w_envs cancer/prepare_diagnosis.sql
psql_w_envs cancer/prepare_performance.sql
psql_w_envs cancer/prepare_lab.sql
psql_w_envs cancer/prepare_lot.sql
psql_w_envs cancer/prepare_stage.sql #! to be updated with TNM for BCA
psql_w_envs cancer/prepare_histology.sql
psql_w_envs cancer/prepare_vital.sql #! divide by zero error
psql_w_envs cancer/prepare_variant.sql
#psql_w_envs caregiver/icd_physician.sql

# prepare attribute
ipython bca/load_attribute.ipy
psql_w_envs cancer/prepare_attribute.sql
    #to truncate trial_attr and crit_attr against each other.
    #to move stage code to attribute_value, stage code_type to code
    #to rescue stage using TNM c/p

# perform the attribute matching
psql_w_envs cancer/match_icd.sql
#psql_w_envs cancer/match_loinc.sql
psql_w_envs cancer/match_aof20200311.sql #update match_aof.. later
psql_w_envs cancer/match_rxnorm_wo_modality.sql #update match_rxnorm later
psql_w_envs bca/prepare_misc_measurement.sql #mv to cancer later
psql_w_envs cancer/match_misc_measurement.sql
psql_w_envs bca/prepare_cat_measurement.sql
psql_w_envs bca/match_cat_measurement.sql #mv to cancer later
psql_w_envs cancer/match_icdo_rex.sql
psql_w_envs cancer/match_stage.sql
psql_w_envs cancer/match_variant.sql

# compile the matches
psql_w_envs bca/master_match.sql  #> master_match
psql_w_envs cancer/master_sheet.sql  #> master_sheet

# match to patients (to be updated)
#psql_w_envs cancer/master_patient.sql #> trial2patients

# download result files for sharing
cd "${working_dir}"
select_from_db_schema_table.py rimsdw ${working_schema}.v_master_sheet > v_master_sheet_$(today_stamp).csv
select_from_db_schema_table.py rimsdw ${working_schema}.v_crit_attribute_used > v_crit_attribute_used_$(today_stamp).csv
select_from_db_schema_table.py rimsdw ${working_schema}.v_demo_w_zip > v_demo_w_zip_$(today_stamp).csv
select_from_db_schema_table.py rimsdw ${working_schema}.v_treating_physician > v_treating_physician_$(today_stamp).csv

#later cancer/perpare_alterations.sql

## matching
