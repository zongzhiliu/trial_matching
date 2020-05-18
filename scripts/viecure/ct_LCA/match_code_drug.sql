set search_path to ct_lca;

DROP TABLE IF EXISTS medication CASCADE;
CREATE TABLE medication as
select person_id, rx_name
FROM viecure_ct.all_rx ar 
JOIN cohort using (person_id)
GROUP BY person_id, rx_name;

select count(*) from medication;

CREATE TABLE _p_a_drug AS
SELECT person_id, attribute_id
, bool_or(case code_type
    when 'drug_name' then dmc.drug_name=rx_name
    when 'drug_modality' then modality=rx_name
    when 'drug_moa_rex' then ct.py_contains(moa, rx_name)
    end) as match
from medication
join crit_attribute_used on code_type like 'drug_%'
join ct.drug_mapping_cat_expn8_20200513 dmc  
    on lower(medication.rx_name) = lower(dmc.drug_name)
    or ct.py_contains(lower(medication.rx_name), lower(dmc.drug_name))
group by person_id, attribute_id
;

SELECT count(*) FROM "_p_a_drug"
where match; --14

CREATE TABLE _p_a_drug_improved AS
with tmp_drug as (
	select *
	FROM medication m 
	JOIN ct.ref_drug_alias_v3 on generic_name = lower(rx_name) or trade_name = lower(rx_name)
)
SELECT person_id, attribute_id
, bool_or(case code_type
    when 'drug_name' then dmc.drug_name=rx_name or dmc.drug_name=generic_name or dmc.drug_name=trade_name
    when 'drug_modality' then modality=rx_name or modality=generic_name or modality=trade_name
    when 'drug_moa_rex' then ct.py_contains(moa, rx_name) or ct.py_contains(moa, generic_name) or ct.py_contains(moa, trade_name)
    end) as match
from tmp_drug
join crit_attribute_used on code_type like 'drug_%'
join ct.drug_mapping_cat_expn8_20200513 dmc  
    on lower(tmp_drug.rx_name) = lower(dmc.drug_name)
    or ct.py_contains(lower(tmp_drug.rx_name), lower(dmc.drug_name))
group by person_id, attribute_id
;

SELECT count(*) FROM "_p_a_drug_improved"
where match; --18709
