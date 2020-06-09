export db_conn=viecure
pgsetup $db_conn
psql -c "create schema if not exists $working_schema"

export working_dir="$HOME/Sema4/${db_conn}/${working_schema}"
export cancer_type_icd="^(C34|162)" #use a ref table later
export cancer_type_icd=$(psql -c \
    "select * from ct.ref_cancer_icd where cancer_type_name='$cancer_type'" \
    | sed '1,2d' | grep -o '\^.*' | sed 's/ //g')
