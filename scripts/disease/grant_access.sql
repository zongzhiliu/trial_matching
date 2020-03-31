grant all on schema ct to mingwei_zhang;
grant all on schema ${working_schema} to mingwei_zhang;
grant all on table ct.ref_lab_loinc_mapping to mingwei_zhang;
grant all on table ct.ref_proc_mapping to mingwei_zhang;
grant all on table ct.ref_rx_mapppinglab_loinc_mapping to mingwei_zhang;
grant all on table ct.ref_drug_mappinglab_loinc_mapping to mingwei_zhang;

set search_path=${working_schema};
grant all on table crit_attribute_used to mingwei_zhang;
grant all on table trial_attribute_used to mingwei_zhang;
