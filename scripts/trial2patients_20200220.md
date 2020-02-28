# log 20200220 - updated for NSCLC and PCA
## create the patient tables in dbeaver/ct_lca.sql
## check the raw trial_attribute file
* skipped: keep only the trail_attr with a 'yes' in inclusion/exclusion
* export the updated trials in horiz form
* export the added trials in vertical form
* convert, merge, check, fix and re-export
* workdir: /Users/zongzhiliu/OneDrive\ -\ Sema4\ Genomics/rimsdw/LCA/nsclc
```python
# the updated trials
df = pd.read_csv('trial_attribute_raw_20200217_updated.csv')
df.inclusion.value_counts() #2108
df.exclusion.value_counts() #1045
res = df.query("inclusion=='yes' | exclusion == 'yes'")
    # fixed typo of 2 yerd, 1 ' yes' in csv
len(res.NCT_ID.value_counts()) #118 trials
res.NCT_ID.value_counts() #10-42 attrs for each trial
res.attribute_id.value_counts().sort_values() #1-115 trials for each attr
res.to_csv('tmp_updated.csv', index=False)

# the added trials
# swap the first two rows in csv, then
raw = pd.read_csv('trial_attribute_raw_20200217_added.csv', skiprows=1, index_col=0)
# seperate inc/exc
sele = raw.columns.str.endswith('.1')
inc = raw[raw.columns[~sele]]
exc = raw[raw.columns[sele]]
exc.columns =  exc.columns.str.replace('.1', '', regex=False)
# unstack and combine inc/exc
res = pd.DataFrame(dict(inclusion=inc.unstack(), exclusion=exc.unstack()))
res.index.names = ['trial_id', 'attribute_id']
# filtered for used
res = res.query("inclusion=='yes' | exclusion == 'yes'")
res.to_csv('tmp_added.csv')
# qc
res = pd.read_csv('tmp_added.csv')
res.inclusion.value_counts() #752 yes
res.exclusion.value_counts() #354 yes
res.query("inclusion=='yes' & exclusion == 'yes'") #None bad
# summary
len(res.trial_id.value_counts()) #42 orignally 67 (wrong) trials
res.trial_id.value_counts() #10-39 attrs for each trial
res.attribute_id.value_counts().sort_values() #1-42 trials for each attr

# combine the two sets
updated = pd.read_csv('tmp_updated.csv')
added = pd.read_csv('tmp_added.csv')
updated.columns = added.columns
res = pd.concat([updated, added])
res.trial_id.value_counts() #160 trials, ok
res.to_csv('trial_attribute_raw_20200217.csv', index=False)

!load_into_db_schema_some_csvs.py rimsdw ct_nsclc trial_attribute_raw_20200217.csv -d
```
## check the raw crit_attribute file and upload
* this will be the source for attribute and crit
```python
df = pd.read_csv('crit_attribute_raw_20200217.csv')
len(df.attribute_id.value_counts()) #172 attrs
max(df.attribute_id.value_counts()) #2!! fixed
df.crit_id.value_counts() #crit has 1-19 attrs for each crit
len(df.crit_id.value_counts())  #87 crit
df[['crit_id', 'crit_name', 'mandated', 'attribute_id', 'attribute_group', 'attribute_name', 'value']]\
    .to_csv('crit_attribute_raw_20200218.csv', index=False)
!load_into_db_schema_some_csvs.py rimsdw ct crit_attribute_raw_20200218.csv
```
## upload new drug mapping from Yun
```
cd '/Users/zongzhiliu/OneDrive - Sema4 Genomics/ClinicalTrials'
load_into_db_schema_some_csvs.py rimsdw ct drug_mapping_cat_expn3.csv
```

## 20200212 regenerate patient level tables in ct_lca
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
```ct_nsclc, trial2patient.sql
create cohort with non-deceasead, NSC patients

create table ct.crit_attribute as
select * from ct.crit_attribute_raw_20200218
;
-- scripts/trial2patients.sql first part
-- qc
select count(*) from trial_attribute_used;
    -- 4259
select count(*) from crit_attribute_used; 
    --135 good
select count(*) from crit_used;
    --83
```
* trial2patient.pptx
```




