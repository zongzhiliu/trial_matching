/*** match attribute using rxnome codes, drug_name, modality, moa
Requires: crit_attribute_used, trial_attribute_used
    latest_lot_drug, $ref_drug_mapping
Results: _p_a_t_rxnorm
*/
drop table if exists _p_a_rxnorm cascade;
drop table if exists _p_a_rxnorm cascade;
create table _p_a_rxnorm as
select person_id, attribute_id
, case code_type
    when 'drug_name' then bool_or(drug_name=lower(code))
    --when 'drug_modality' then bool_or(modality=lower(code)) --quickfix
    when 'drug_moa_rex' then bool_or(ct.py_contains(moa, code, 'i')) -- bug fix
    end as match
from latest_lot_drug h
join ${ref_drug_mapping} m using (drug_name)
join crit_attribute_used on code_type in ('drug_name', 'drug_moa_rex') --, 'drug_modality')
group by person_id, attribute_id, code_type, code
;
create or replace view _p_a_t_rxnorm as
select person_id, trial_id, attribute_id, match
from _p_a_rxnorm
join trial_attribute_used using (attribute_id)
;
/*
select attribute_id, attribute_name, match
, count(distinct person_id) patients
from _p_a_rxnorm
join crit_attribute_used using (attribute_id)
where match
group by attribute_id, attribute_name, match
order by attribute_id, match
;
*/
