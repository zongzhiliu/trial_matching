#for each disease
## prepare the ct_{disease} tables for each criterion-attribute
## prepare a config file: ct_{disease}.toml?

#for each trial
## update the trial config file: trial.toml
run convert_criteria_to_sql.py
    ##output: {desease}/{trial}.sql

##run {disease}/{trial}.sql
