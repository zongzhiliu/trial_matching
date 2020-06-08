# utils
# rdmsdw
export rdmsdw_host='s4-dmsdw.cswcn2wwxepe.us-east-1.redshift.amazonaws.com'
export rdmsdw_bastion='ec2-3-214-186-216.compute-1.amazonaws.com'

# rimsdw
export rimsdw_host='auto-abst-redshift-cluster.cpgxfro2regq.us-east-1.redshift.amazonaws.com'
export rimsdw_bastion='auto-abst-bastion-host-lb-542f9513ec56d4ad.elb.us-east-1.amazonaws.com'

function start_ssh_tunnel {
    tunnel_name=$1; shift
    lport_dhost_rport=$1; shift
    user_at_remote=$1; shift
    other_args=$@
    cmd="AUTOSSH_DEBUG=1 autossh -g -M 0 -N -L $lport_dhost_rport $user_at_remote $other_args \
            -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
            -o ServerAliveInterval=10 -o ServerAliveCountMax=1 \
            -o ExitOnForwardFailure=yes -o ControlMaster=no -o ControlPath=/dev/null"
    if ! screen -ls | grep -q "[0-9]\+.$tunnel_name\s"; then
        screen -S "$tunnel_name" -dm bash -c "$cmd"
    fi
}
#usage: start_ssh_tunnel rimsdw 9999:$rimsdw_host:5439 zach_liu@$rimsdw_bastion

export pgpass_prefix="$HOME/.pgpass_"
# set up for postgre connection using PGPASSFILE
# usage: pgsetup rdmsdw
function pgsetup {
    export PGPASSFILE="${pgpass_prefix}${1}"
    IFS=':' read PGHOST PGPORT PGDATABASE PGUSER PGPASSWORD < ${PGPASSFILE}
    export PGHOST; export PGPORT; export PGDATABASE; export PGUSER # Need to export for psql
    export PGPASSWORD  # Let's just use the pgpass file instead case someone does `env`
}

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

function load_from_csv { fname=$1
    load_into_db_schema_some_csvs.py ${db_conn} ${working_schema} ${working_dir}/${fname}
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

function load_to_pdesign { tv=$1
    cd ${working_dir}
    ln -s ${tv}_$(today_stamp).csv ${working_schema}.${tv}_$(today_stamp).csv
    load_into_db_schema_some_csvs.py pdesign db_data_bridge ${working_schema}.${tv}_$(today_stamp).csv -d
    cd -
}
