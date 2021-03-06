export db_conn=viecure
export working_schema=ct
export working_dir=$HOME/Sema4/viecure/ct
source util/util.sh
pgsetup viecure
# cohort, demo, histology, stage
psql_w_envs gen_demo.sql
# demo_plus: person_id
# , date_of_birth, gender_name, race_name, ethnicity_name
# , date_of_death, last_visit_date
# --, address_zip
#     -- patient
#     -- patient_demographic
#     -- patient_history_items

psql_w_envs viecure/viecure_ct/gen_cancer_dx.sql
# cancer_dx: person_id, cancer_type_name
# , histologic_type_name, histologic_icdo
# , overall_stage, imputed_stage
# 
#     ref_cancer_icd: cancer_type_name, cancer_type_icd
#     -- dx
#     patient_dx: person_id, dx_date, icd, icd_code, description
#     patient_histology and references
#     patient_stage and references

psql_w_envs viecure/viecure_ct/gen_tests.sql
psql_w_envs viecure/viecure_ct/gen_rx.sql
psql_w_envs viecure/viecure_ct/gen_others.sql
