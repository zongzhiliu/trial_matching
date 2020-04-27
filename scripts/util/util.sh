# utils

#using $working_schema
function psql_w_envs {
    { echo "set search_path=${working_schema:-public};" & cat $1; } \
    | substitute_env_vars_in_pipe.py \
    | psql --echo-all --no-psqlrc -v ON_ERROR_STOP=1
}

# export a table/view form working_schema to working_dir with today_stamp
function export_w_today { tv=$1
    select_from_db_schema_table.py ${db_conn} ${working_schema}.${tv} > ${working_dir}/${tv}_$(today_stamp).csv
}

function mysql_w_envs {
    cat $1 \
    | substitute_env_vars_in_pipe.py \
    | mysql --defaults-file="$HOME/.my.pharma.cnf" --verbose
}

function today_stamp {
    date +%Y%m%d
}

function load_to_pharma { tv=$1
    cd ${working_dir}
    ln -s ${tv}_$(today_stamp).csv ${working_schema}.${tv}_$(today_stamp).csv
    load_into_db_schema_some_csvs.py pharma db_data_bridge ${working_schema}.${tv}_$(today_stamp).csv -d
    cd -
}
