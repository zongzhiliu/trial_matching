# https://aact.ctti-clinicaltrials.org/snapshots
# https://dataschool.com/learn-sql/how-to-start-a-postgresql-server-on-mac-os-x/
# Note that: PGPORT is used with starting server and psql
export PGPORT=5432
pg_ctl -D /usr/local/var/postgres start
psql aact_back -U zongzhiliu

echo 'set search_path=ctgov;' > _export_each_table_to_csv.sql
cat ctgov_table_names.txt | while read tname || [[ -n $line ]]; do
    echo "copy $tname to '/Users/zongzhiliu/Downloads/tmp/$tname.csv' DELIMITER ',' CSV HEADER;" >> _export_each_table_to_csv.sql
done

psql aact_back -U zongzhiliu -f _export_each_table_to_csv.sql

for f in *.csv; do
    #[[ "$f" > "detailed_descritions" ]] && 
    load_into_db_schema_some_csvs.py -d --copy_params 'ACCEPTINVCHARS' rimsdw2 ctgov $f
    load_into_db_schema_some_csvs.py -d --copy_params 'ACCEPTINVCHARS' rdmsdw ctgov $f
done
# Fixed by improving load_into_db_schema_some_csvs.py
# detailed_descrtions.csv loading errors: 
# eligibilites failed
# String contains invalid or unsupported UTF8 codepoints. Bad UTF8 hex sequence: ef b7 a1 (error 6) 
