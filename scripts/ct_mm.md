# repopulate the ct_mm schema
* stage, histolgy not needed
* alterations later
* icds. labs, etc to limit by last three years?

## workflow
* dbeaver settings
@set cancer_type=MM
@set cancer_type_icd=^(C90|230)
```bash
export cancer_type=MM
export cancer_type_icd="^(C90|230)"
export working_dir="$HOME/OneDrive - Sema4 Genomics/rimsdw/${cancer_type}"
export working_schema="ct_${cancer_type}"
source util/util.sh

psql_w_envs cancer/prepare_patients.sql
psql_w_envs cancer/prepare_lot.sql
psql_w_envs cancer/prepare_vital.sql
psql_w_envs caregiver/icd_physician.sql

psql_w_envs mm/setup.sql #to be replaced with config file
psql_w_envs cancer/prepare_attribute.sql
psql_w_envs cancer/match_icd.sql
psql_w_envs cancer/match_loinc.sql
psql_w_envs cancer/match_rxnorm.sql
psql_w_envs cancer/match_misc_measurement.sql
psql_w_envs mm/match_mm_active_status.sql

#later cancer/perpare_alterations.sql
```
## check the crit_attribute table
* icd_rex: to make the code_raw into a code_rex: '^(' || replace(code_raw, '.', '[.]') || ')'
    * add ICD9 code for MM, later systemtic conversion the icd9 to icd10?
    * convert code_raw, code_ext to code as icd rex
    * calc nPatients used the icd.
    * match atrribute
    * implement the temporay restriction (attribute_value)

* loinc:
    * check the ie_unit and loinc_unit, make unit_conversion table later
* drug therapy
    * upload the ref_drug_mapping table

## check, convert and load the trial/crit_attribute table
* align then trial_attribute and crit_ttribute table
* export the trial_attribute table
* check and convert
```ipython
#cd $working_dir
script_dir = '/Users/zongzhiliu/git/trial_matching/scripts'
cd {script_dir}
%run -i -n util/convert_trial_attribute.py
%run -i -n util/util.py #today_stamp
cd -

#trial_attribute
raw_csv = 'trial_attribute_raw_.csv'
res = convert_trial_attribute(raw_csv)
summarize_ie_value(res)
res_csv=f'trial_attribute_raw_{today_stamp()}.csv'
res.to_csv(res_csv, index=False)
!ln -sf {res_csv} trial_attribute_raw.csv
!load_into_db_schema_some_csvs.py -d rimsdw ct_mm trial_attribute_raw.csv

# crit_attribute
raw_csv='crit_attribute_raw_.csv'
res = convert_crit_attribute(raw_csv)
summarize_crit_attribute(res)
res_csv=f'crit_attribute_raw_{today_stamp()}.csv'
res.to_csv(res_csv, index=False)
!ln -sf {res_csv} crit_attribute_raw.csv
!load_into_db_schema_some_csvs.py -d rimsdw ct_mm crit_attribute_raw.csv
```
