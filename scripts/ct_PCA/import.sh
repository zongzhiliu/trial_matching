############################################################## 
# incomplete do not run
# the workflow to create and populate ct_${cancer} schema
# requires:
# ct.py_contains, .ref_drug_mapping .ref_lab_mapping
### runnable
# setup
source util/util.sh #psql_w_envs
source ct_PCA/config.sh
pgsetup ${db_conn}
psql -c "create schema if not exists ${working_schema}"

# psql_w_envs caregiver/icd_physician.sql
#psql_w_envs cancer/prepare_reference.sql
psql_w_envs ct_PCA/quickfix_prepare_reference.sql  #> ref tables
psql_w_envs ct_PCA/setup.sql  #> ref tables, crit_attribute_used

# prepare patient tables
psql_w_envs cancer/prepare_patients.sql  #> demo and other patient tables
    #prepare_patients.sql is incomplete, to be replaced with other prepare_ modules
# psql_w_envs cancer/prepare_stage.sql  #> stage
psql_w_envs ct_PCA/quickadd_impute_stage.sql  #> stage
psql_w_envs cancer/prepare_histology.sql  #> histology
#psql_w_envs cancer/prepare_alterations.sql  #> _variant_significant
psql_w_envs ct_PCA/prepare_patients.sql  #> gleason
psql_w_envs ct_PCA/quickfix_prepare_drug.sql #> _drug

# match to attributes
psql_w_envs cancer/match_attributes.sql #>_pa_stage/ecog/karnofsky/lot
psql_w_envs cancer/match_attributes__age.sql #> pat_age
psql_w_envs cancer/match_attributes__vital.sql #> pat_weight/bloodpressure
psql_w_envs cancer/match_attributes__disease.sql #> pa_disease
psql_w_envs cancer/match_attributes__drug_therapy.sql #> pa_/chemo/immuno/hormon/targeted
psql_w_envs cancer/match_lab_pa.sql #>pa_lab
psql_w_envs cancer/match_lab_pat.sql #>pat_lab
psql_w_envs ct_PCA/match_attributes.sql  #> pat_gleason, pa_histology
psql_w_envs ct_PCA/quickadd_match_disease_status.sql #> pa_disease_status
psql_w_envs ct_PCA/quickadd_match_PSA.sql #>pat_psa_at_diagnosis

### Runable
# compile the matches
psql_w_envs ct_PCA/master_match.sql  #> master_match
psql_w_envs ct_PCA/quickadd_attribute_plus.sql #> v_crit_attribute_used, v_trial_attribute_used
psql_w_envs disease/master_sheet.sql  #> master_sheet
#psql_w_envs disease/logic_to_levels.sql
#psql_w_envs disease/master_patient.sql #> trial2patients
# python cancer/master_tree.py generate patient counts at each logic branch,
# and dynamic visualization file for each trial.

### Runnable
# download and deliver
ipython cancer/download_master_patient.ipy
psql_w_envs disease/master_sheet_mapping.sql
psql_w_envs cancer/quickfix_master_sheet_lca_pca.sql
source cancer/download_master_sheet.sh
source cancer/deliver_master_sheet.sh
export logic_cols='logic_l1_id'
export disease=${cancer_type}
mysql_w_envs disease/expand_master_sheet.sql

##############################################################
# never run
#psql_w_envs ct_PCA/master_match.sql  #> master_match
#psql_w_envs cancer/master_sheet.sql  #> master_sheet
#todo
#python compile_matches.py | psql #compile all the _p_a_tables and _p_a_t_talbles to master_match

# match to patients
#psql_w_envs trial2patients.sql  #> trial2patients
# ### !! donot run
# # prepare attribute
# ipython pca/load_attribute.ipy
# psql_w_envs cancer/prepare_attribute.sql
# 
# ### !! donot run
# # prepare patient data
# psql_w_envs ${working_schema}/quickfix_prepare_drug.sql # drug mapping needed
# #psql_w_envs cancer/prepare_vital.sql #! divide by zero error
# psql_w_envs cancer/prepare_cohort.sql
# psql_w_envs cancer/prepare_diagnosis.sql
# psql_w_envs cancer/prepare_performance.sql
# psql_w_envs cancer/prepare_lab.sql
# psql_w_envs cancer/prepare_lot.sql # drug mapping needed
# psql_w_envs cancer/prepare_stage.sql
# psql_w_envs cancer/prepare_histology.sql
# psql_w_envs cancer/prepare_variant.sql
# psql_w_envs cancer/prepare_biomarker.sql
# #psql_w_envs caregiver/icd_physician.sql
# 
# ### !!do not run
# # perform the attribute matching
# #psql_w_envs cancer/match_loinc.sql
# psql_w_envs cancer/match_icd.sql #later: make a _p_a table, and a _p_a_t view
# psql_w_envs cancer/match_aof20200311.sql #update match_aof.. later
# psql_w_envs cancer/match_rxnorm_wo_modality.sql #: check missing later
# psql_w_envs pca/prepare_misc_measurement.sql #mv to cancer later
# psql_w_envs cancer/match_misc_measurement.sql
# psql_w_envs pca/prepare_cat_measurement.sql #menopausal to be cleaned
# psql_w_envs pca/match_cat_measurement.sql #mv to cancer later
# psql_w_envs cancer/match_icdo_rex.sql
# psql_w_envs cancer/match_stage.sql
# psql_w_envs cancer/match_variant.sql
# psql_w_envs cancer/match_biomarker.sql #later: code_type=cat/num_measurement

