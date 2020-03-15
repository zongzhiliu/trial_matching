/*** match attribute using ICD-O codes
Requires: cohort, crit_attribute_used, trial_attribute_used
    histology_icdo
Results: _p_a_t_icd_rex
*/
drop table if exists _p_a_t_icdo_rex cascade;
create table _p_a_t_icdo_rex as
with cau as (
    select attribute_id, code_type, code
    from crit_attribute_used
    where code_type in ('icdo_rex')
)
select person_id, trial_id, attribute_id
, bool_or(pca.py_re_search(histologic_icdo, code, '') is not null) as match
from histology
cross join cau
join trial_attribute_used using (attribute_id)
group by person_id, trial_id, attribute_id
, code_type, code
;
/*qc
select attribute_id, attribute_name, attribute_value, match, count(distinct person_id)
from _p_a_t_icdo_rex join crit_attribute_used using (attribute_id)
where match
group by attribute_id, attribute_name, attribute_value, match
order by attribute_id, attribute_name, attribute_value, match
;
*/

