/***
Requires:
    crit_attribute_used, ref_histology_mapping
    histology
Results:
    _p_a_histology
*/

drop table if exists _p_a_histology cascade;
create table _p_a_histology as
with cau as (
    select attribute_id, code_ext
    from crit_attribute_used
    where code_type='text_mapping' and code='histology'
)
select person_id, histologic_type_name as patient_value
, attribute_id
, case code_ext
    when 'nsclc' then nsclc
    when 'squamous' then squamous
    when 'non_squamous' then non_squamous
    when 'sclc' then sclc
    when 'net' then net
    end as match
from cohort join histology h using (person_id)
join ref_histology_mapping m using (histologic_type_name)
cross join cau
;

create view qc_histology as
select attribute_name, attribute_value, count(*)
from _p_a_histology join crit_attribute_used ca using (attribute_id)
where match
group by attribute_name, attribute_value
;
select * from qc_histology;
