# ct_sclc import
```dbeaver
@set cancer_type=SCLC
@set cancer_type_icd=^(C34|162)
```

```bash
source util/util.sh
export cancer_type='NSCLC'
export cancer_type_icd='^(C34|162)'
psql_w_envs caregiver/icd_physician.sql
```
## prepare the patient tables, match attributes and patients
```bash
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



