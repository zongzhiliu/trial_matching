create table _rx_used as
select drug_name rx_name, drug_generic_name rx_generic
, nvl(rx_name, '') + '| ' + nvl(rx_generic, '') rx_names
, count(*) records, count(distinct person_id) patients
from latest_alt_drug
group by rx_name, rx_generic
;

create table drug_rx_mapping as
select drug_name, rx_name, rx_generic, records, patients
from ct.drug_mapping_cat_expn8_20200513
left join _rx_used on ct.py_contains(rx_names, drug_name, 'i')
;

create or replace view qc_drug_rx_mapping as
select drug_name, rx_name, rx_generic, records, patients
from drug_rx_mapping
order by records is null, drug_name, -records, rx_name
;
select * from qc_drug_rx_mapping;
