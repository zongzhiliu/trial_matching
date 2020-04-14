# the workflow for ct_PCA (updated 2020-04-24)
## config/input
```
export cancer_type=PCA
export cancer_type_icd='^(C61|185)'

export ref_drug_mapping=ct.drug_mapping_cat_expn6
export ref_lab_mapping=ct.ref_lab_loinc_mapping
export ref_proc_mapping=ct.ref_proc_mapping_20200325
export ref_rx_mapping=ct.ref_rx_mapping_20200325
ref_histology_mapping

_crit_attribute_raw=ct.crit_attribute_used_lca_pca_20200410
_crit_attribute_raw_updated=ct.crit_attribute_used_lca_pca_20200410
_trial_attribute_raw=trial_attribute_raw_20200223;
```
## setup: evaluate and convert the references
* ref_drug_mapping
* ref_lab_mapping
* trial_attribute_used: filter, deduplicate, ie_flag, ie_value
* crit_attribute_used: filter by tau, deduplicate

## prepare patient data from cplus/dev_patient/msdw
* demo, demo_plus
* stage: imputed from tnm, psa, gleason
* histology, gleason
* latest_icd
* latest_lab
* latest_lot_drug
* lasest_ecog, karnofsky

## match the attributes for each patient and trial
* _p_a_disease, disease_status (metastates)
* _p_a_chemotherapy, hormone_therapy, targetedtherapy, immunotherapy
* _p_a_lab, stage, lot, ecog, karnofsky
* _p_a_t_lab, gleason, blood_pressure, weight, psa_at_diagnosis

## compile and update the match, ca, ta
* master_match
* crit_attribute_updated: pruned by match, updated by ca_raw_updated
* trial_attribute_updated: pruned by match, mandatory, logic updated with cau

## match the patients after applying negation, mandatory and logic
* trial_logic_levels
* master_patient_summary

## deliver to external (person_id masked)
* crit_attribute_expanded
* master_sheet_expanded
* demo_w_zip
* caregiver_zip

