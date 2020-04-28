/*** match attribute using drug_name, modality, moa
Requires: crit_attribute_used
, latest_lot_drug, $ref_drug_mapping
Results: _p_a_drug
*/
drop table if exists _p_a_drug cascade;
create table _p_a_drug as
select person_id, attribute_id
, bool_or(case code_type
    when 'drug_name' then drug_name=code
    when 'drug_name_rex' then ct.py_contains(drug_name, '^('+code+')') --quickfix
    when 'drug_modality' then modality=code
    when 'drug_moa_rex' then ct.py_contains(moa, code)
    end) as match
from latest_lot_drug h
join ${ref_drug_mapping} m using (drug_name)
join crit_attribute_used on code_type like 'drug_%'
group by person_id, attribute_id
;

create view qc_match_drug as
select attribute_id, attribute_group, attribute_name, attribute_value
, count(distinct person_id) patients
from _p_a_drug
join crit_attribute_used using (attribute_id)
where match
group by attribute_id, attribute_group, attribute_name, attribute_value
order by attribute_id
;
select * from qc_match_drug;
