# requires: working_schema
cd $working_dir
## demo
#ln -sf v_demo_w_zip_$(today_stamp).csv \
#    ${working_schema}.v_demo_w_zip.csv
#load_into_db_schema_some_csvs.py pharma db_data_bridge \
#    ${working_schema}.v_demo_w_zip.csv

# attribute
ln -s v_crit_attribute_expanded_$(today_stamp).csv \
    ${working_schema}.v_crit_attribute_expanded_$(today_stamp).csv
load_into_db_schema_some_csvs.py pharma db_data_bridge \
    ${working_schema}.v_crit_attribute_expanded_$(today_stamp).csv -d

# master_sheet_n
ln -s v_master_sheet_expanded_$(today_stamp).csv \
    ${working_schema}.v_master_sheet_expanded_$(today_stamp).csv
load_into_db_schema_some_csvs.py pharma db_data_bridge \
    ${working_schema}.v_master_sheet_expanded_$(today_stamp).csv -d
cd -
