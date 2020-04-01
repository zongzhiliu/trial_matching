cd /Users/zongzhiliu/Sema4/rdmsdw/ct
mask_magic=3040
cancer=CRC
function etl_treating_physicians { cancer=$1
    select_from_db_schema_table.py rimsdw -q "
            select person_id+${mask_magic} as person_id
            , caregiver, zip_code, num_visits
            from ct_${cancer}.treating_physicians
            order by person_id" > \
        ${cancer}.treating_physicians.csv
    load_into_db_schema_some_csvs.py pharma db_data_bridge \
        ${cancer}.treating_physicians.csv
}
etl_treating_physicians NSCLC
etl_treating_physicians SCLC
etl_treating_physicians PCA
etl_treating_physicians MM
etl_treating_physicians BCA
etl_treating_physicians CRC
