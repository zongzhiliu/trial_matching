# s4_trial_matching
clinical trial matching with the patients in MSDW based databases

## Workflow
[The working draft here] (scripts/Readme.md/)

## Requirements
[The working draft here] (https://sema4genomics.sharepoint.com/:w:/r/sites/HAI/Shared%20Documents/Project/Clinical_Trial/setupTrialMatchingWorkflow.docx?d=wae54625881d1426e827df929d6ba7245&csf=1&e=gUJyxq)

## The code structure
* [/scripts](scripts/):  
The current version.

* /patient:  
Later: Prepare the patient attributes to enable matching

* /trial: <br/>
Later: Prepare the trial criteria to enable matching

* /matching: <br>
Later: Create the matching matrix for each trial, each patient [trial_id, patient_id, criteron, match (T/F/Null)]

* /ex:  
Later: Example workflow

* /tests  
Later: Unit tests and integration tests.

To run all the tests,
```pytest -sv```
<!---
## Installation
From the directory of the package,
``` pip install .
```

## Usage
TBD
--->
