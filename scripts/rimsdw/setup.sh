export db_conn=rimsdw
export person_mask=3040 #add this to person_id to mask it.
pgsetup $db_conn
psql -c "create schema if not exists $working_schema"

export working_dir="$HOME/Sema4/${db_conn}/${working_schema}"
export cancer_type_icd=$(psql -c \
    "select * from ct.ref_cancer_icd where cancer_type_name='$cancer_type'" \
    | sed '1,2d' | grep -o '\^.*' | sed 's/ //g')
