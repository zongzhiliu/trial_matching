# create patient_attr
psql -f ../patient/make_patient_attr.sql

# create the mathing table
python ../matching/convert_criteria_to_sql.py < LCA_trial_matching.csv
psql -c 'drop table if exists ct_nsclc._ex_match'
psql -c 'create table ct_nsclc._ex_match (trial_id text, person_id text
, age BOOL
, ecog BOOL
, stage BOOL
, previously_treated BOOL
)'
for f in tmp/*.sql; do
    cmd=$(cat $f | sed '1i\
        insert into ct_nsclc._ex_match
        ')
    echo $cmd >> combined.sql; echo ';' >> combined.sql
    #echo $cmd | psql -f -
done
psql -f combined.sql

#
#for f in tmp/*.sql; do
#    echo $f
#    cmd="$(cat $f)"
#    echo $cmd
#    query_from_oa_db "$cmd" > ${f%.*}.csv
#done
