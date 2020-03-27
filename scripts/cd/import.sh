# the workflow to create and populate ct_${cancer} schema
# requires:
# ct.py_contains, .ref_drug_mapping .ref_lab_mapping
source cd/config.sh
source util/util.sh
pgsetup rdmsdw
psql -c "create schema if not exists ${working_schema}"
psql_w_envs cancer/prepare_reference.sql

# load mapping tables
cd ${working_dir}
load_into_db_schema_some_csvs.py rdmsdw ct_cd proc_mapping.csv
cd -

# prepare patient data
#psql_w_envs cancer/prepare_vital.sql #! divide by zero error
psql_w_envs disease/prepare_cohort.sql
psql_w_envs disease/prepare_diagnosis.sql
psql_w_envs disease/prepare_vital.sql
psql_w_envs disease/prepare_sochx.sql
psql_w_envs disease/prepare_procedure.sql # drug mapping needed
psql_w_envs disease/prepare_medication.sql # drug mapping needed
psql_w_envs disease/prepare_lab.sql
#psql_w_envs caregiver/icd_physician.sql

# prepare attribute
ipython cd/load_attribute.ipy
psql_w_envs cancer/prepare_attribute.sql
    #later: to move stage code to attribute_value, stage code_type to code
    #later: rescue stage using TNM c/p

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
cd "${working_dir}"
select_from_db_schema_table.py rimsdw ${working_schema}.v_trial_patient_count > \
    ${cancer_type}.v_trial_patient_count_$(today_stamp).csv
select_from_db_schema_table.py rimsdw ${working_schema}.v_master_sheet > \
    ${cancer_type}.v_master_sheet_$(today_stamp).csv
select_from_db_schema_table.py rimsdw ${working_schema}.v_crit_attribute_used > \
    ${cancer_type}.v_crit_attribute_used_$(today_stamp).csv
select_from_db_schema_table.py rimsdw ${working_schema}.v_demo_w_zip > \
    ${cancer_type}.v_demo_w_zip_$(today_stamp).csv
select_from_db_schema_table.py rimsdw ${working_schema}.v_treating_physician > \
    ${cancer_type}.v_treating_physician_$(today_stamp).csv

# load to pharma mysql server
sed 's/,True/,1/g;s/,False/,0/g' ${cancer_type}.v_master_sheet_$(today_stamp).csv \
    > ${cancer_type}.v_master_sheet.csv
load_into_db_schema_some_csvs.py pharma db_data_bridge \
    ${cancer_type}.v_master_sheet.csv -d

ln -sf ${cancer_type}.v_crit_attribute_used_$(today_stamp).csv \
    ${cancer_type}.v_crit_attribute_used.csv
load_into_db_schema_some_csvs.py pharma db_data_bridge \
    ${cancer_type}.v_crit_attribute_used.csv

ln -sf ${cancer_type}.v_demo_w_zip_$(today_stamp).csv \
    ${cancer_type}.v_demo_w_zip.csv
load_into_db_schema_some_csvs.py pharma db_data_bridge \
    ${cancer_type}.v_demo_w_zip.csv
cd -
