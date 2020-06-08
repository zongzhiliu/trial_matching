/*** match attribute using drug_name, modality, moa
Requires: crit_attribute_used
, latest_lot_drug, $ref_drug_mapping
Results: _p_a_drug
*/
drop table latest_alt_drug cascade;
CREATE TABLE latest_alt_drug AS
SELECT person_id, lower(drug_name) drug_name, lower(drug_generic_name) drug_generic_name
FROM cplus_from_aplus.medications m 
JOIN cplus_from_aplus.drugs d using (drug_id)
JOIN cohort using (person_id);

DROP TABLE IF EXISTS _p_a_drug CASCADE;
CREATE TABLE _p_a_drug AS
SELECT person_id, attribute_id
, bool_or(case code_type
    when 'drug_name' then dmce.drug_name=code
    when 'drug_modality' then modality=code
    when 'drug_moa_rex' then ct.py_contains(moa, code, 'i')
    end) as match
from latest_alt_drug lrd
join drug_rx_mapping drm on lrd.drug_name = rx_name 
join crit_attribute_used au on code_type like 'drug_%'
join ct.drug_mapping_cat_expn10 dmce on (drm.drug_name = dmce.drug_name)
group by person_id, attribute_id
;

create view qc_match_drug_final as
select attribute_id, attribute_group, attribute_name, attribute_value
, count(distinct person_id) patients
from _p_a_drug_final
join crit_attribute_used using (attribute_id)
where match
group by attribute_id, attribute_group, attribute_name, attribute_value
order by attribute_id
;
