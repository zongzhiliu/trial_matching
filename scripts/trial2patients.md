# log 20200111

## check the raw trial_attribute file
* fixed typo of yerd, ' yes' in excel
* keep only the trail_attr with a 'yes' in inclusion/exclusion
```python
df = pd.read_csv('trial_attribute_raw_20200111.csv')
df.inclusion.value_counts() #2519, 2462
df.exclusion.value_counts() #966, 936 
len(df.NCT_ID.value_counts()) #118 trials
df.NCT_ID.value_counts() #11-45 attrs for each trial
df.attribute_id.value_counts() #1-119 trials for each attr
```

## check the raw crit_attribute file
* this will be the source for attribute and crit
```python
df = pd.read_csv('crit_attribute_raw_20200111.csv')
len(df.attribute_id.value_counts()) #204 attrs
max(df.attribute_id.value_counts())
max(df.crit_id.value_counts()) #crit has 1-121 attrs
len(df.crit_id.value_counts()) #121 crit
```
## upload the raw trail_attribute
```bash
load_into_db_schema_some_csvs.py rimsdw ct_nsclc trial_attribute_raw_20200111.csv -d
```

## check the crit_atrribute file
```bash
load_into_db_schema_some_csvs.py rimsdw ct_nsclc crit_attribute_raw_20200111.csv -d
```
## report attribute_used, crit_used in ct_nsclc 
```trial2patient.sql
```

## prepatient patient level tables in ct_lca (no change)
```ct_lca.sql
stage
_variant_listed_gene_pivot
lot
patient_demo
```

## perform attribute matching in ct_lca (no change)
```ct_lca_to_attribute.sql
    subquery to write into the master config file later (query for each attribute)
    to use attribute id instead of attribute_name in the current version
    complete with code for ct_pca_patient_attribute
_p_a_stage #ok from state
    clinical_status not implemented
_p_a_mutation #incomplete from _variant_listed_gene_pivot
    c_met, ret, tp53, smo, ptch-1 not implemented
    biomarker not implemented
_p_a_lot #ok from lot
    treatment not implemented
_p_a_age #ok from patient_demo
_p_a_ecog #ok from patient_demo_ecog_final
    karnofsky not implemented
_p_a_histology #ok from ct.lca_histology_category
_p_a_chemotherapy #ok from p_lot_drugs
_p_a_immunotherapy #incomplete from p_lot_drugs
    other, IL not implemented
_p_a_targetedtherapy #incomplete from p_lot_drugs
    vgef, ros not implemented
_p_a_cns_disease #incomplete from latest_icd
    brain met active not implemented
_p_a_other_desease #incomplete from latest_icd
    autoimmune and CHF not implemented
_p_a_lab #ok from person_lab_attribute_mapping
```
## generate patient_attibute and mastersheet in ct_nsclc
```trial2patient.sql
* trial2patient.pptx
```




