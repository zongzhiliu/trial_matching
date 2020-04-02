# require: working_dir, working_schema, cancer_type
cd "${working_dir}"
select_from_db_schema_table.py rimsdw ${working_schema}.v_trial_patient_count > \
    ${cancer_type}.v_trial_patient_count_$(today_stamp).csv
select_from_db_schema_table.py rimsdw ${working_schema}.v_treating_physician > \
    ${cancer_type}.v_treating_physician_$(today_stamp).csv
cd -
