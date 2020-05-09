# start PD attribut ematting
source rimsdw/ct_nlp_pd/config.sh
source util/util.sh
pgsetup $db_conn
psql_w_envs rimsdw/ct_nlp_pd/setup.sql

# match to attributes
psql_w_envs viecure/ct_lca/match_test.sql
psql_w_envs viecure/ct_LCA/match_dx.sql --ct_NSCLC/match_code_icd.sql # > pa_icd_rex
psql_w_envs rimsdw/ct_NSCLC/match_code_variant.sql #> pa_variant
psql_w_envs rimsdw/ct_NSCLC/match_code_biomarker.sql #> pa_biomarker
psql_w_envs rimsdw/ct_nlp_pd/match_text_mapping__histology.sql  #> pa_text_mapping (histology)
psql_w_envs rimsdw/ct_nlp_pd/prepare_text_measure.sql #(stage)
psql_w_envs rimsdw/ct_nlp_pd/match_text_measure__stage.sql # > pa_text_measure (stage)

psql_w_envs rimsdw/ct_nlp_pd/prepare_numeric_measure.sql
psql_w_envs rimsdw/ct_nlp_pd/match_numeric_measure.sql # > pa_numeric_measure (age, ecog, karnofsky, lot)
psql_w_envs rimsdw/ct_NSCLC/match_code_drug.sql #> pa_drug

# compile the matches
psql_w_envs ct_NSCLC/master_match.sql  #> master_match
# psql_w_envs ct_NSCLC/update_attributes.sql #> crit/trial_attribute_updated
# psql_w_envs cancer/trial_logic_levels.sql #> trial_logic_levels
# psql_w_envs ct_PCA/master_patient.sql #> master_pathient_summary
# export_w_today master_patient_summary
# # deliver
# psql_w_envs ct_NSCLC/expand_attributes.sql #> crit_attribute_expanded, master_sheet_expanded
# export_w_today qc_attribute_match_summary
# export_w_today v_crit_attribute_expanded
# load_to_pharma v_crit_attribute_expanded
# export_w_today v_master_sheet_expanded
# load_to_pharma v_master_sheet_expanded
