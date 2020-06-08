drop table if exists _drug_alias_plus cascade;
create table _drug_alias_plus as
with dav as ( -- renaming the field names
    select lower(generic_name) drug_name, btrim(trade_name) alias
	from ct.ref_drug_alias_v3
), dae as ( -- renaming the field names
	select lower(drug_name) drug_name, btrim(other_names) alias
	from ct.drug_alias_expn10
)
select drug_name, alias from dav where alias !='' union --quickfix
select drug_name, alias from dae where alias !='' union --quickfix
select drug_name, drug_name from ref_drug_mapping union --quickfix
select drug_name, drug_name from dav
;

-- select * from _drug_alias_plus order by drug_name, alias limit 99;
drop table if exists _drug_alias_cat cascade;
create table _drug_alias_cat as 
select drug_name, listagg(distinct alias, '| ') within group (order by alias) as aliases
from _drug_alias_plus
group by drug_name
;

drop table if exists latest_alt_drug cascade;
CREATE TABLE latest_alt_drug AS
SELECT person_id, lower(drug_name) drug_name, lower(drug_generic_name) drug_generic_name
FROM cplus_from_aplus.medications m 
JOIN cplus_from_aplus.drugs d using (drug_id)
JOIN cohort using (person_id);

drop table if exists "_rx_used" cascade;
create table _rx_used as
select drug_name rx_name, drug_generic_name rx_generic
, nvl(rx_name, '') + '| ' + nvl(rx_generic, '') rx_names
, count(*) records, count(distinct person_id) patients
from latest_alt_drug
group by rx_name, rx_generic
;

drop table if exists drug_rx_mapping cascade;
create table drug_rx_mapping as
select drug_name, alias, rx_name, rx_generic, records, patients
from ref_drug_mapping
join "_drug_alias_plus" using (drug_name)
left join _rx_used on ct.py_contains(rx_names, alias, 'i')
;

