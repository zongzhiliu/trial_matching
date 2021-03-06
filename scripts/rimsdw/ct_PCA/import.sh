############################################################## 
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
psql_w_envs ct_PCA/setup.sql  #> ref tables, trial/crit_attribute_used

# prepare patient tables
# psql_w_envs cancer/prepare_patients.sql  #> demo and other patient tables
    #prepare_patients.sql is incomplete, to be replaced with other prepare_ modules
# psql_w_envs cancer/prepare_stage.sql  #> stage
psql_w_envs ct_PCA/quickadd_impute_stage.sql  #> stage
psql_w_envs cancer/prepare_histology.sql  #> histology
#psql_w_envs cancer/prepare_alterations.sql  #> _variant_significant
psql_w_envs ct_PCA/prepare_patients.sql  #> gleason
psql_w_envs ct_PCA/quickfix_prepare_drug.sql #> _drug
    #not used in the pipeline yet

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

# compile the matches
psql_w_envs ct_PCA/master_match.sql  #> master_match
psql_w_envs ct_PCA/update_attributes.sql #> crit/trial_attribute_updated
psql_w_envs cancer/trial_logic_levels.sql #> trial_logic_levels
psql_w_envs ct_PCA/master_patient.sql #> master_pathient_summary

#psql_w_envs cancer/quickfix_master_sheet_lca_pca.sql
#psql_w_envs ct_PCA/master_sheet.sql  #> master_sheet to be deprecated
psql_w_envs ct_PCA/expand_attributes.sql #> crit_attribute_expanded, master_sheet_expanded
source ct_PCA/download_master_sheet_expanded.sh
source ct_PCA/deliver_master_sheet_expanded.sh

