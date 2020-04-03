# Document the workflow matching trial eligibility criteria to patients.

## API
* Input:
    * crit_attribute.csv: the attribute table
    * trial_attribute.csv: the inc/exc value of each attribute for each trial
    * reference tables: drug_mapping, lab_mapping, ...
    * patient data: msdw, cplus, dev_patient_info, dev_patient_clinical, ...
* Output:
    * trial_attribute_expanded: each unique i/e value becomes a attribute atom
    * master_match: the match for each (trial, attribute, patient)
        * adjusted: adjusted the raw match with inc/exc then mandatory
    * master_patient: number of eligible patients for each trial.
        * number of patients for each trial at each logic levels
* Algorithm (steps):
    1. Seting up
        * config
        * linking to reference
    1. Loading attributes
        * crit_attribute
        * trial_attribute
        * mutual prunning
    1. Prepare patient data
        * demo, lab, proc, dx, rx, ...
    1. Attribute matching
        * master_match
    1. Patient matching
        * adjusted match
        * logic_summary
        * trial_summary
    1. Delivering
        * crit_attribute_expanded
        * master_sheet_expanded
        * demo_w_zip
        * treating_physicans
## install requirements
### draft here
https://sema4genomics.sharepoint.com/:w:/r/sites/HAI/Shared%20Documents/Project/Clinical_Trial/setupTrialMatchingWorkflow.docx?d=wae54625881d1426e827df929d6ba7245&csf=1&e=gUJyxq


