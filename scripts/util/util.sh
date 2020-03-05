# utils

#using $working_schema
function psql_w_envs {
    { echo "set search_path=${working_schema};" & cat $1; } \
    | substitute_env_vars_in_pipe.py \
    | psql --echo-all --no-psqlrc -v ON_ERROR_STOP=1
}
