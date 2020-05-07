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
