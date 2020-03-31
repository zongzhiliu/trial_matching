/* CD patient with complications
IBD026	CD of Small Intestine, with Complication	Yes	5,751
IBD028	CD of Large Intestine, with Complication	Yes	5,444
*/
with pa_match as (
	select person_id, attribute_id
	, bool_or(match) as match
	from _p_a_t_diagnosis
	where attribute_id in ('IBD026', 'IBD028')
	group by person_id, attribute_id
), p_match as (
	select bool_or(match) as match
	from pa_match
	group by person_id
)
select count(*) from p_match where match
;
    -- 7080

/* UC with complications
IBD036    Ulcerative Proctitis with Complication    Yes    3,188
*/
with pa_match as (
	select person_id, attribute_id
	, bool_or(match) as match
	from _p_a_t_diagnosis
	where attribute_id in ( 'IBD034', 'IBD036', 'IBD038', 'IBD041')
	group by person_id, attribute_id
), p_match as (
	select bool_or(match) as match
	from pa_match
	group by person_id
)
select count(*) from p_match where match
;
    -- 3188

select * from crit_attribute_used where attribute_id ~ 'IBD06[0-6]';

/* procedure matching with ICD vs CPT
IBD062	Ileostomy	Yes	cpt_mapping	706
IBD060	Stoma	Yes	icd_rex	1,037

attribute_id	attribute_name	attribute_value	code_type	true_patients
IBD065	Acquired Absence of GI Tract	Yes	icd_rex	1,386
IBD064	Anastomosis	Yes	icd_rex	690
IBD066	Colectomy	Yes	cpt_mapping	1,929
*/
with pat_match as (
    select person_id, attribute_id, trial_id, match from _p_a_t_diagnosis union all
    select person_id, attribute_id, trial_id, match from _p_a_t_procedure
),  pa_match as (
	select person_id, attribute_id
	, bool_or(match) as match
	from pat_match
	where attribute_id in ( 'IBD060', 'IBD062')
	group by person_id, attribute_id
), p_match as (
	select bool_and(match) as match
	from pa_match
	group by person_id
)
select count(*) from p_match where match
;
    -- 356
with pat_match as (
    select person_id, attribute_id, trial_id, match from _p_a_t_diagnosis union all
    select person_id, attribute_id, trial_id, match from _p_a_t_procedure
),  pa_match as (
	select person_id, attribute_id
	, bool_or(match) as match
	from pat_match
	where attribute_id ~ 'IBD06[456]'
	group by person_id, attribute_id
), p_match_cpt as (
	select person_id, bool_or(match) as match
	from pa_match
    where attribute_id ~ 'IBD066'
	group by person_id
), p_match_icd as (
	select person_id, bool_or(match) as match
	from pa_match
    where attribute_id ~ 'IBD06[45]'
	group by person_id
), p_match as (
    select person_id, bool_and(match) as match
    from ( select person_id, match from p_match_cpt union all
        select person_id, match from p_match_icd)
    group by person_id
)
--select count(*) from p_match_cpt where match; --1929
--select count(*) from p_match_icd where match; --1767
select count(*) from p_match where match --631
;


/*********
 * explore
 */
select * from _kinds_of_procedures
where lower(procedure_description) ~
--'transfusion'
'stem cell'
--'pluripotent'
;

create table _kinds_of_rx_ as
select rx_name, rx_generic, context_material_code, context_name, count(*) records
from _rx
group by rx_name, rx_generic, context_material_code, context_name
; -- code is not helpfule
select * from _kinds_of_rx_ order by rx_name, rx_generic, context_name, context_material_code;

create table _kinds_of_rx as
select rx_name, rx_generic, count(*) records
from rx
group by rx_name, rx_generic
;
select * from _kinds_of_rx
where lower(rx_name || '; ' || rx_generic) ~
'hydroxy'
;
select * from dx
where lower(description) ~ 'alcohol abuse'
;

drop table _kinds_of_icds;
create table _kinds_of_icds as
select context_name, context_diagnosis_code, description
, count(*) records
from dx
where description != 'NOT AVAILABLE'
group by context_name, context_diagnosis_code, description
;
grant all on schema ct_scd to wen_pan;
select * from dmsdw_2019q1.d_person limit 10;

/***
* master_sheet
*/
select count(*) records
, count(distinct new_attribute_id) attributes
, count(distinct trial_id) trials
, count(distinct person_id) patients
from v_master_sheet_new
;
/* old delivery
# download result files for sharing
cd "${working_dir}"
select_from_db_schema_table.py rimsdw ${working_schema}.v_trial_patient_count > \
    ${cancer_type}.v_trial_patient_count_$(today_stamp).csv
select_from_db_schema_table.py rimsdw ${working_schema}.v_master_sheet > \
    ${cancer_type}.v_master_sheet_$(today_stamp).csv
select_from_db_schema_table.py rimsdw ${working_schema}.v_crit_attribute_used > \
    ${cancer_type}.v_crit_attribute_used_$(today_stamp).csv
select_from_db_schema_table.py rimsdw ${working_schema}.v_demo_w_zip > \
    ${cancer_type}.v_demo_w_zip_$(today_stamp).csv
select_from_db_schema_table.py rimsdw ${working_schema}.v_treating_physician > \
    ${cancer_type}.v_treating_physician_$(today_stamp).csv

# load to pharma mysql server
sed 's/,True/,1/g;s/,False/,0/g' ${cancer_type}.v_master_sheet_$(today_stamp).csv \
    > ${cancer_type}.v_master_sheet.csv
load_into_db_schema_some_csvs.py pharma db_data_bridge \
    ${cancer_type}.v_master_sheet.csv -d

ln -sf ${cancer_type}.v_crit_attribute_used_$(today_stamp).csv \
    ${cancer_type}.v_crit_attribute_used.csv
load_into_db_schema_some_csvs.py pharma db_data_bridge \
    ${cancer_type}.v_crit_attribute_used.csv

ln -sf ${cancer_type}.v_demo_w_zip_$(today_stamp).csv \
    ${cancer_type}.v_demo_w_zip.csv
load_into_db_schema_some_csvs.py pharma db_data_bridge \
    ${cancer_type}.v_demo_w_zip.csv
cd -
# python cancer/master_tree.py generate patient counts at each logic branch,
# and dynamic visualization file for each trial.

# download result files for sharing
cd "${working_dir}"
select_from_db_schema_table.py rdmsdw ${working_schema}.v_trial_patient_count > \
    ${disease}.v_trial_patient_count_$(today_stamp).csv
select_from_db_schema_table.py rdmsdw ${working_schema}.v_master_sheet > \
    ${disease}.v_master_sheet_$(today_stamp).csv
select_from_db_schema_table.py rdmsdw ${working_schema}.v_crit_attribute_used > \
    ${disease}.v_crit_attribute_used_$(today_stamp).csv
select_from_db_schema_table.py rdmsdw ${working_schema}.v_demo_w_zip > \
    ${disease}.v_demo_w_zip_$(today_stamp).csv
select_from_db_schema_table.py rdmsdw ${working_schema}.v_treating_physician > \
    ${disease}.v_treating_physician_$(today_stamp).csv

# load to pharma mysql server
sed 's/,True/,1/g;s/,False/,0/g' ${disease}.v_master_sheet_$(today_stamp).csv \
    > ${disease}.v_master_sheet.csv
load_into_db_schema_some_csvs.py pharma db_data_bridge \
    ${disease}.v_master_sheet.csv -d

ln -sf ${disease}.v_crit_attribute_used_$(today_stamp).csv \
    ${disease}.v_crit_attribute_used.csv
load_into_db_schema_some_csvs.py pharma db_data_bridge \
    ${disease}.v_crit_attribute_used.csv

ln -sf ${disease}.v_demo_w_zip_$(today_stamp).csv \
    ${disease}.v_demo_w_zip.csv
load_into_db_schema_some_csvs.py pharma db_data_bridge \
    ${disease}.v_demo_w_zip.csv
*/
