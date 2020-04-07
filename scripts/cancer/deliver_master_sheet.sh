# requires: cancer_type
cd $working_dir
# attribute
ln -sf v_crit_attribute_used_new_$(today_stamp).csv \
    ${cancer_type}.v_crit_attribute_used_new.csv
load_into_db_schema_some_csvs.py pharma db_data_bridge \
    ${cancer_type}.v_crit_attribute_used_new.csv -d

# demo
ln -sf ${cancer_type}.v_demo_w_zip_$(today_stamp).csv \
    ${cancer_type}.v_demo_w_zip.csv
load_into_db_schema_some_csvs.py pharma db_data_bridge \
    ${cancer_type}.v_demo_w_zip.csv

# master_sheet
load_into_db_schema_some_csvs.py pharma db_data_bridge \
    ${cancer_type}.v_master_sheet_n.csv -d
cd -
