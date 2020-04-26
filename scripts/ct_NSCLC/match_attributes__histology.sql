/***
Requires:
    crit_attribute_used, ref_histology_mapping
    histology
Results:
    _p_a_histology
*/

drop table if exists _p_a_histology cascade;
create table _p_a_histology as
select person_id, histologic_type_name as patient_value
, attribute_id
, case attribute_id
    when 1 then nsclc
    when 2 then squamous
    when 3 then non_squamous
    when 4 then sclc
    end as match
from histology h
join ${ref_histology_mapping} m using (histologic_type_name)
cross join crit_attribute_used
where attribute_id in (1, 2, 3, 4)
;

create view qc_histology as
select attribute_name, attribute_value, count(*)
from _p_a_histology join crit_attribute_used ca using (attribute_id)
where match
group by attribute_name, attribute_value
;
select * from qc_histology;
