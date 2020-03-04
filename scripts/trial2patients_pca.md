# log 20200223 - updated for PCA

## check the raw trial_attribute file
* move the the first to the third row in csv, then
* export the updated and added into csv files.
  76 updated + 47 added = 123
* convert to vertical form, check, fix, merge and export
```python
# fix typo and extra spaces in text editor, then
raw = pd.read_csv('trial_attribute_raw_20200223_updated.csv',
    skiprows=2, index_col=0)
raw.columns #76*2

# seperate inc/exc
sele = raw.columns.str.endswith('.1')
inc = raw[raw.columns[~sele]]
exc = raw[raw.columns[sele]]
exc.columns =  exc.columns.str.replace('.1', '', regex=False)
assert all(inc.columns==exc.columns)

# unstack and combine inc/exc
res = pd.DataFrame(dict(inclusion=inc.unstack(), exclusion=exc.unstack()))
res.index.names = ['trial_id', 'attribute_id']
res['inclusion'] = res.inclusion.str.strip()
res['exclusion'] = res.exclusion.str.strip()
res.inclusion.value_counts() #yes or numeric
res.exclusion.value_counts() #yes or numeric or 'yes <4W'
updated = res

# added
raw = pd.read_csv('trial_attribute_raw_20200223_added.csv',
    skiprows=2, index_col=0)
len(raw.columns) #47*2

# seperate inc/exc
sele = raw.columns.str.endswith('.1')
inc = raw[raw.columns[~sele]]
exc = raw[raw.columns[sele]]
exc.columns =  exc.columns.str.replace('.1', '', regex=False)
assert all(inc.columns==exc.columns)
 # unstack and combine inc/exc
res = pd.DataFrame(dict(inclusion=inc.unstack(), exclusion=exc.unstack()))
res.index.names = ['trial_id', 'attribute_id']
 # check
res['inclusion'] = res.inclusion.str.strip()
res['exclusion'] = res.exclusion.str.strip()
res.inclusion.value_counts() #yes or numeric
res.exclusion.value_counts() #yes or numeric
added = res

## merge, filter, export, upload
res = pd.concat([updated.reset_index(), added.reset_index()])
mask = res.inclusion.isna() & res.exclusion.isna()
res = res[~mask]
res.shape #3362
res.trial_id.value_counts() #6-45 attrs for each trial
res.attribute_id.value_counts() #1-123 trials for each attr
mask = ~res.inclusion.isna() & ~res.exclusion.isna()
    #7 entries with both inc/exc checked, remove them for now
result = res[~mask]
result.shape #3355
result.to_csv('trial_attribute_raw_20200223.csv', index=False)
!load_into_db_schema_some_csvs.py rimsdw ct_pca trial_attribute_raw_20200223.csv -d
```
# skip: check the raw crit_attribute file and upload
* this will be the source for attribute and crit
```python
df = pd.read_csv('crit_attribute_raw_20200223.csv')
len(df.attribute_id.value_counts()) #253 attrs
max(df.attribute_id.value_counts()) #good
df.crit_id.value_counts() #crit has 1-19 attrs for each crit
len(df.crit_id.value_counts())  #132 crit
!load_into_db_schema_some_csvs.py rimsdw ct crit_attribute_raw_20200221.csv
```

## prepare the patient tables, match attributes and patients
```bash
function psql_w_envs {
    cat $1 | substitute_env_vars_in_pipe.py \
    | psql --echo-all --no-psqlrc -v ON_ERROR_STOP=1
}
export cancer_type=PCA
export cancer_type_icd=^(C61|185)
psql_w_envs pca/setup.sql  #> ref tables, crit_attribute_used

# prepare patient tables
psql_w_envs cancer/prepare_patients.sql  #> demo and other patient tables
psql_w_envs cancer/prepare_stage.sql  #> stage
psql_w_envs cancer/prepare_histology.sql  #> stage
psql_w_envs cancer/prepare_alterations.sql  #> stage
psql_w_envs pca/prepare_patients.sql  #> specific patient tables

# match to attributes
psql_w_envs cancer/match_attributes.sql  #>_p_a_..., _p_a_t_...
psql_w_envs cancer/match_lab_pa.sql #>_p_a_lab
psql_w_envs cancer/match_lab_pat.sql #>_p_a_t_lab
psql_w_envs pca/match_attributes.sql  #> _p_a_t_gleason, p_a_histology
psql_w_envs pca/master_match.sql  #> master_match
psql_w_envs cancer/master_sheet.sql  #> master_sheet
#todo
#python compile_matches.py | psql #compile all the _p_a_tables and _p_a_t_talbles to master_match

# match to patients
psql_w_envs trial2patients.sql  #> trial2patients
```



