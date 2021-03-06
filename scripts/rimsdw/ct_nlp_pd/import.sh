# start PD attribut ematting
source rimsdw/ct_nlp_pd/config.sh
source util/util.sh
pgsetup $db_conn
psql_w_envs rimsdw/ct_nlp_pd/setup.sql

# match to attributes
psql_w_envs rimsdw/ct_NSCLC/match_code_variant.sql #> pa_variant
psql_w_envs rimsdw/ct_NSCLC/match_code_biomarker.sql #> pa_biomarker
psql_w_envs viecure/ct_LCA/match_dx.sql # > pa_icd_rex
psql_w_envs rimsdw/ct_nlp_pd/match_code_lab.sql # > pa_loinc

# hard coded lab queries, to be reorganized later
psql_w_envs rimsdw/ct_nlp_pd/quickadd__latest_lab_mapped.sql # > _latest_lab_mapped
psql_w_envs rimsdw/ct_nlp_pd/match_query_lab.sql
psql_w_envs rimsdw/ct_nlp_pd/match_text_mapping__histology.sql  #> pa_histology
psql_w_envs rimsdw/ct_nlp_pd/match_text_measure__stage.sql # > pa_stage
psql_w_envs rimsdw/ct_nlp_pd/quickadd_drug_rx_mapping.sql

psql_w_envs rimsdw/ct_nlp_pd/prepare_numeric_measure.sql
psql_w_envs rimsdw/ct_nlp_pd/match_numeric_measure.sql # > pa_numeric_measure (age, ecog, karnofsky, lot)
psql_w_envs rimsdw/ct_nlp_pd/match_code_drug.sql #> pa_drug

# compile the matches
psql_w_envs rimsdw/ct_nlp_pd/master_match.sql  #> master_match
########################################################### next
# # deliver
psql_w_envs rimsdw/ct_nlp_pd/master_sheet.sql  #> master_match
export_w_today v_crit_attribute_expanded
load_to_pdesign v_crit_attribute_expanded
export_w_today v_master_sheet_expanded
load_to_pdesign v_master_sheet_expanded
