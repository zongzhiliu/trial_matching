/*** match attribute using drug_name, modality, moa
Requires: crit_attribute_used
, latest_lot_drug, $ref_drug_mapping
Results: _p_a_drug
*/
CREATE TABLE latest_rx_drug AS
SELECT person_id, rx_name, rx_generic
	, rx_date
FROM (select *, row_number() over (
        partition by person_id, rx_name, rx_generic
        order by -age_in_days)
    FROM dev_patient_info_lca.medications 
    JOIN prod_references.person_mrns on mrn = medical_record_number
    )
JOIN cohort using (person_id)
WHERE ROW_NUMBER = 1;

DROP TABLE IF EXISTS _p_a_drug CASCADE;
CREATE TABLE _p_a_drug AS
SELECT person_id, attribute_id
, bool_or(case code_type
    when 'drug_name' then drug_name=code
    when 'drug_modality' then modality=code
    when 'drug_moa_rex' then ct.py_contains(moa, code)
    end) as match
from latest_rx_drug lrd
join crit_attribute_used on code_type like 'drug_%'
join ct.drug_mapping_cat_expn7 on ct.py_contains(nvl(lower(rx_name), ''), drug_name) 
group by person_id, attribute_id
;

CREATE TABLE latest_alt_drug AS
SELECT person_id, drug_name
FROM cplus_from_aplus.medications m 
JOIN cplus_from_aplus.drugs d using (drug_id)
JOIN cohort using (person_id);

CREATE TABLE _p_a_drug_alt AS
SELECT person_id, attribute_id
, bool_or(case code_type
    when 'drug_name' then dmc.drug_name=code
    when 'drug_modality' then modality=code
    when 'drug_moa_rex' then ct.py_contains(moa, code)
    end) as match
from latest_alt_drug lad 
join crit_attribute_used on code_type like 'drug_%'
join ct.drug_mapping_cat_expn7 dmc on ct.py_contains(nvl(lower(lad.drug_name), ''), dmc.drug_name) 
group by person_id, attribute_id
;
select count(*) from "_p_a_drug_alt" pad2 where match; --2654 --2763 --2747

create view qc_match_drug_alt as
select attribute_id, attribute_group, attribute_name, attribute_value
, count(distinct person_id) patients
from _p_a_drug_alt
join crit_attribute_used using (attribute_id)
where match
group by attribute_id, attribute_group, attribute_name, attribute_value
order by attribute_id
;
