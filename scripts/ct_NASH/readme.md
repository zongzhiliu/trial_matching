# 20200331 to remap the crit_attribute table and the master sheet
## workflow
* (with kyeryoung) Add mandatory_default and logic to the new attribute table
* QC query to find the implemented attributes and those with multiple ie_values; add to [the new attribute file](
https://sema4genomics.sharepoint.com/:x:/r/sites/HealthcareAnalyticsInformatics/_layouts/15/Doc.aspx?sourcedoc=%7B657db537-7108-4d4b-bd80-4782c89a1d5d%7D&action=edit&activeCell=%27in%27!G98&wdInitialSession=a05c1a1f-b8c5-4df0-9b70-03c1ac6c6cc2&wdRldC=1)
* Load the attribute table (crit_attribute_used_raw) and clean it to keep only with only implemented attributes the crit_attribute_used
```bash
load_into_db_schema_some_csvs.py rdmsdw ${working_schema} crit_attribute_raw.csv -d
psql -f nash/master_sheet_mapping.sql
```
* process the attribute logic
* Make the crit_attribute_used_new
* Generate a clean trial_attribute_used table

* Compile a clean master_sheet
* Make the master_sheet_new
* Deliver

