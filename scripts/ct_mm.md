# report attribute matching and patient matching for the MM patients

## paitent data based on cplus_from_aplus; dev_patient_clinical; dev_patient_info; prod_msdw
* stage, histolgy not needed
* alterations not needed
* cohort limited by icd report in the last three years.

## check the crit_attribute table
* icd_rex (code_type): to make the code_raw into a code_rex: '^(' || replace(code_raw, '.', '[.]') || ')'
    * ICD10 in code_raw, ICD10 in code_ext
    * tempo restriction in attribute_value, time unit in years in attribute_value_norm
* loinc (code_type):
    * check the ie_unit and loinc_unit, make unit_conversion table later
    * loinc code in code_raw, ie_unit in code_ext, conversion factor from patient to ie in patient_value_norm
* drug therapy
    * upload the ref_drug_mapping table
    * matching with drug_name, drug_modality or drug_moa_rex (code_type)
* misc_measurement (code_type)
    * age, ecog, karnofsky, lot
* match_query (code_type)
    * specific sql query to a "_t_a_p_{code}" table

## check, convert and load the trial/crit_attribute table
* align then trial_attribute and crit_ttribute table with attribute_id
    * https://sema4genomics.sharepoint.com/:x:/r/sites/HAI/Shared%20Documents/Project/Clinical_Trial/Multiple%20myeloma/crit_attribute_raw_.xlsx?d=wbbedfc24850a4b278191938c53676428&csf=1&e=oEAQjq
* export the trial_attribute table: 
    * copy attribute_id and the trial columns to a new sheet
    * switch the first and third row, export to a csv filel (trial_attribute_raw_.csv) to the working_dir
* export the crit_attribute_table:
    * copy the relevant columns (without note, for example) to a new sheet
    * export to a csv file (crit_attribute_.csv) to the working_dir
* config and run (with checking) the following script in ipython to transform and load to ct_mm schema
```ipython
# config
HOME=os.environ['HOME']
cancer_type='MM'
working_dir=f"{HOME}/OneDrive - Sema4 Genomics/rimsdw/{cancer_type}"
script_dir = '/Users/zongzhiliu/git/trial_matching/scripts'

cd {script_dir}
%run -i -n util/convert_attribute.py
%run -i -n util/util.py #today_stamp
cd {working_dir}

#trial_attribute
raw_csv = 'trial_attribute_raw_.csv'
res = convert_trial_attribute(raw_csv)
summarize_ie_value(res)
res_csv=f'trial_attribute_raw_{today_stamp()}.csv'
res.to_csv(res_csv, index=False)
!ln -sf {res_csv} trial_attribute_raw.csv
!load_into_db_schema_some_csvs.py -d rimsdw ct_{cancer_type} trial_attribute_raw.csv

# crit_attribute
raw_csv='crit_attribute_raw_.csv'
res = convert_crit_attribute(raw_csv)
summarize_crit_attribute(res)
res_csv=f'crit_attribute_raw_{today_stamp()}.csv'
res.to_csv(res_csv, index=False)
!ln -sf {res_csv} crit_attribute_raw.csv
!load_into_db_schema_some_csvs.py -d rimsdw ct_{cancer_type} crit_attribute_raw.csv
```
## To prepare patient data, perform attribute matching, patient matching and export results
* config and run the following script
```bash
# config
export cancer_type=MM
export cancer_type_icd="^(C90|230)"
export working_dir="$HOME/OneDrive - Sema4 Genomics/rimsdw/${cancer_type}"
export working_schema="ct_${cancer_type}"
export script_dir="$HOME/git/trial_matching/scripts'

cd ${script_dir}
source mm/import.sh
```
## for debugging in dbeaver
```
@set cancer_type=MM
@set cancer_type_icd=^(C90|230)
set search_path=ct_$(cancer_type)
...
```
