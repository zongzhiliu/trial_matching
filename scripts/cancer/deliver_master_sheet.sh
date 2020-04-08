# requires: working_schema
cd $working_dir
# attribute
ln -sf v_crit_attribute_used_new_$(today_stamp).csv \
    ${working_schema}.v_crit_attribute_used_new.csv
load_into_db_schema_some_csvs.py pharma db_data_bridge \
    ${working_schema}.v_crit_attribute_used_new.csv -d

# demo
ln -sf v_demo_w_zip_$(today_stamp).csv \
    ${working_schema}.v_demo_w_zip.csv
load_into_db_schema_some_csvs.py pharma db_data_bridge \
    ${working_schema}.v_demo_w_zip.csv

# master_sheet_n
ln -sf v_master_sheet_n.csv \
    ${working_schema}.v_master_sheet_n.csv
load_into_db_schema_some_csvs.py pharma db_data_bridge \
    ${working_schema}.v_master_sheet_n.csv -d
cd -
