drop table if exists _p_a_rxnorm cascade;
create table _p_a_rxnorm as
SELECT r.mrn, attribute_id,
case code_type
	when 'drug_name' then bool_or(drug_name=code)
    when 'drug_modality_rex' then bool_or(modality=lower(code))
    when 'drug_moa_rex' then bool_or(ct.py_contains(moa, code, 'i') is null)
	when 'drug_moa_rex_le_tempo' then bool_or(ct.py_contains(moa, code, 'i') is null)
    end as match
FROM rx r
JOIN _all_name an using(rx_name)
LEFT JOIN ct.drug_mapping_cat_expn6 mp using (drug_name)
JOIN crit_attribute_used cau on code_type in ('drug_name', 'drug_moa_rex', 'drug_modality_rex', 'drug_moa_rex_le_tempo')
GROUP BY mrn, attribute_id, code_type;