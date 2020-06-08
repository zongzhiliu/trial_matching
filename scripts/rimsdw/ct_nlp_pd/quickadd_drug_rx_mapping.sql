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
from ct.drug_mapping_cat_expn10
join "_drug_alias_plus" using (drug_name)
left join _rx_used on ct.py_contains(rx_names, alias, 'i')
;
select * from qc_drug_rx_mapping;
