--set search_path=ct_NSCLC;

create or replace view qc_attribute_match_summary as
with av as (
    select new_attribute_id, attribute_match
    , count(distinct person_id) patients
    from v_master_sheet_new
    group by new_attribute_id, attribute_match
), pivot as (
    select new_attribute_id
    , nvl(sum(case when attribute_match is True then patients end), 0) patients_true
    , nvl(sum(case when attribute_match is False then patients end), 0) patients_false
    , nvl(sum(case when attribute_match is Null then patients end), 0) patients_null
    from av group by new_attribute_id
)
select new_attribute_id, old_attribute_id attribute_id
, patients_true, patients_false, patients_null
, attribute_group+'| '+attribute_name+'| '+attribute_value as attribute_title
from pivot join v_crit_attribute_used_new using (new_attribute_id)
order by regexp_substr(old_attribute_id, '[0-9]+')::int, new_attribute_id
;
/*
select_from_db_schema_table.py rimsdw ct_nsclc.qc_attribute_match_summary > ${working_dir}/qc_attribute_match_summary_$(today_stamp).csv
*/
create view v_NCT04032704 as select * from ct_nsclc.trial_attribute_used
join crit_attribute_used using(attribute_id) where trial_id='NCT04032704';

/*
select_from_db_schema_table.py rimsdw ${working_schema}.v_NCT04032704 \
    > ${working_dir}/v_NCT04032704_$(today_stamp).csv
*/


/*qc of lot
-- debug
select distinct lot from m_lot;
select modality, count(*)
from m_lot
group by modality ;
--ok
select count(distinct person_id) from lot where n_lot>0;
select count(distinct person_id) from modality_lot where n_lot>0;

select modality, count(distinct person_id) patients
from modality_lot
where n_lot>0
group by modality
;
-- debug
with tmp as(
select distinct drug_name from _line_of_therapy
left join ${ref_drug_mapping} using (drug_name)
where modality is null
)
select * 
from resource.all_cancer_drugs_list ac
--from ${ref_drug_mapping}
join tmp on lower(ac.drug_name)=tmp.drug_name
;
*/

/*
select * from _master_match
order by person_id, trial_id, attribute_id
limit 100;
with total as (
select count(*) from _master_match
), uniq as (
select count(*) from (select distinct * from _master_match)
), pat as (
select count(*) from (select distinct person_id, trial_id, attribute_id from _master_match)
)
select * from total union all
select * from uniq union all
select * from pat
;

*/

