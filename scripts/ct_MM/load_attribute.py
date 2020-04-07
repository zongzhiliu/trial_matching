# config
HOME=os.environ['HOME']
cancer_type= os.environ['cancer_type']
working_dir=os.environ['working_dir']
script_dir = os.environ['script_dir']

%run -i -n {script_dir}/util/util.py #today_stamp
%run -i -n {script_dir}/util/convert_attribute.py

#!cd {working_dir}
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
