# ct_nsclc import
```dbeaver
@set cancer_type=NSCLC
@set cancer_type_icd=^(C34|162)
```

```bash
source util/util.sh
export cancer_type='NSCLC'
export cancer_type_icd='^(C34|162)'
psql_w_envs caregiver/icd_physician.sql
psql_w_envs caregiver/treating_physician_scott.sql
```
## 20200421 to update the nsclc pipeline
```
create table ct.nsclc_trial_attribute_raw_20200223 as
 select * from ct_nsclc.trial_attribute_raw_20200223;



