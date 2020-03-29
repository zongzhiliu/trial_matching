cd /Users/zongzhiliu/Sema4/rdmsdw/ct
schema=ct_pca
function etl_treating_physicians { schema=$1
    select_from_db_schema_table.py rimsdw ${schema}.treating_physicians > \
        ${schema}.treating_physicians.csv
    load_into_db_schema_some_csvs.py pharma db_data_bridge \
        ${schema}.treating_physicians.csv
}
etl_treating_physicians ct_nsclc
etl_treating_physicians ct_sclc
etl_treating_physicians ct_pca
etl_treating_physicians ct_mm
etl_treating_physicians ct_bca
etl_treating_physicians ct_crc
