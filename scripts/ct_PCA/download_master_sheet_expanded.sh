# Requires: db_conn, working_schema, today_stamp()

cd $working_dir
# attribute
select_from_db_schema_table.py ${db_conn} ${working_schema}.v_crit_attribute_expanded > \
    v_crit_attribute_expanded_$(today_stamp).csv

# demo
select_from_db_schema_table.py ${db_conn} ${working_schema}.v_demo_w_zip > \
    v_demo_w_zip_$(today_stamp).csv

# master_sheet
select_from_db_schema_table.py ${db_conn} ${working_schema}.v_master_sheet_expanded > \
    v_master_sheet_expanded_$(today_stamp).csv
cd -
