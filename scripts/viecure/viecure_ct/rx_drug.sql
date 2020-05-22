/* Result: rx_drug, rx_drug_annotating
Requires: all_rx; ct.drug_alias
*/
create table source_rx as
select distinct rx_name from all_rx
;

drop table if exists _rx_drug cascade;
create table _rx_drug as
select distinct rx_name, drug_name
from source_rx
join ct._drug_alias_plus
on ct.py_contains(rx_name, '\\b'+alias+'\\b', 'i')
;
-- select * from _rx_drug order by drug_name, rx_name limit 99;

drop view _rx_drug_annotating;
create or replace view _rx_drug_annotating as
select rx_name, drug_name, aliases, null::bool is_valid
from source_rx
left join _rx_drug using (rx_name)
left join ct._drug_alias_cat using (drug_name)
order by drug_name, lower(rx_name)
;

-- select * from _rx_drug_annotating order by drug_name, rx_name limit 99;
