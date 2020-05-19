-- set search_path to ct_lca;

DROP TABLE IF EXISTS _medication CASCADE;
CREATE TABLE _medication as
select person_id, rx_name
FROM viecure_ct.all_rx ar
JOIN cohort using (person_id)
GROUP BY person_id, rx_name;

select count(*) from medication;

--TODO: make rx_mapping_table of (drug_name, rx_name), then join using (drug_name)
drop TABLE if exists _p_a_drug cascade;
CREATE TABLE _p_a_drug AS
SELECT person_id, attribute_id
, bool_or(case code_type
    when 'drug_name' then dm.drug_name=code
    when 'drug_modality' then modality=code
    when 'drug_moa_rex' then ct.py_contains(moa, code)
    end) as match
from _medication m
join crit_attribute_used on code_type like 'drug_%'
join ref_drug_mapping dm
    on ct.py_contains(lower(m.rx_name), lower(dm.drug_name))
group by person_id, attribute_id
;

create view qc_match_drug as
with cau as (
    select * from crit_attribute_used
    where code_type like 'drug_%'
), matched as (
    SELECT attribute_id
    , count(distinct person_id) as patients
    from _p_a_drug
    where match
    group by attribute_id
)
select attribute_id, attribute_name, attribute_value
, nvl(patients, 0) matched_patients
from cau
left join matched using (attribute_id)
order by attribute_id
;

-- drug_alias need to cover all of drug_mapping
-- drug_names needed for convenience of qc
drop table if exists _rx_drug cascade;
create table _rx_drug as
with rx as ( -- unique rx_names
    select distinct rx_name from _medication
), da as ( -- renaming the field names
    select lower(generic_name) drug_name, trade_name alias
    from ct.ref_drug_alias_v3
), da_plus as ( -- add missing drug_names from ref_drug_mapping
    select drug_name, nvl(alias, drug_name) alias
    from ref_drug_mapping
    left join da using (drug_name)
)
select distinct rx_name, drug_name
from rx
join da_plus
on rx_name ilike '%'+drug_name+'%' or rx_name ilike '%'+alias+'%'
;

create temporary table _drug_aliases as
with da as ( -- renaming the field names
    select lower(generic_name) drug_name, trade_name alias
    from ct.ref_drug_alias_v3
), da_plus as ( -- add missing drug_names from ref_drug_mapping
    select drug_name, nvl(alias, drug_name) alias
    from ref_drug_mapping
    left join da using (drug_name)
)
select drug_name, listagg(distinct alias, '| ') within group (order by alias) as aliases
from da_plus
group by drug_name
;

create view _rx_drug_annotating as
select rx_name, drug_name, aliases, 1 is_valid
from _rx_drug
join _drug_aliases using (drug_name)
order by drug_name, rx_name
;
drop TABLE if exists _p_a_drug_improved cascade;
CREATE TABLE _p_a_drug_improved AS
SELECT person_id, attribute_id
, bool_or(case code_type
    when 'drug_name' then drug_name=code
    when 'drug_modality' then modality=code
    when 'drug_moa_rex' then ct.py_contains(moa, code)
    end) as match
from crit_attribute_used
join _medication on code_type like 'drug_%'
join _rx_drug using (rx_name)
join ref_drug_mapping using (drug_name)
group by person_id, attribute_id
;

create or replace view qc_match_drug_improved as
with cau as (
    select * from crit_attribute_used
    where code_type like 'drug_%'
), matched as (
    SELECT attribute_id
    , count(distinct person_id) as patients
    from _p_a_drug_improved
    where match
    group by attribute_id
)
select attribute_id, attribute_name, attribute_value
, nvl(patients, 0) matched_patients
from cau
left join matched using (attribute_id)
order by attribute_id
;
select * from qc_match_drug_improved;

select * from qc_match_drug                                                                   │
 join qc_match_drug_improved using(attribute_id, attribute_name, attribute_value)
 order by attribute_id;

SELECT count(*) FROM "_p_a_drug_improved"
where match;
--2936
