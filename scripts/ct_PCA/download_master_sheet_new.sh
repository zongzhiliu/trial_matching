# Requires: db_conn, working_schema, today_stamp()

cd $working_dir
# attribute
select_from_db_schema_table.py ${db_conn} ${working_schema}.v_crit_attribute_used_new > \
    v_crit_attribute_used_new_$(today_stamp).csv

# demo
select_from_db_schema_table.py ${db_conn} ${working_schema}.v_demo_w_zip > \
    v_demo_w_zip_$(today_stamp).csv

# master_sheet
select_from_db_schema_table.py ${db_conn} ${working_schema}.v_master_sheet_new > \
    v_master_sheet_new.csv
cd -
