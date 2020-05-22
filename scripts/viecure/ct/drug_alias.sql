/* > drug_alias_plus, _rx_drug, rx_drug_annotating
Input: drug_mapping_cat_expn_v9, drug_alias_expn_v9, ref_drug_alias_v3

Later: mv _rx_drug, rx_drug_anntation to viecure_ct
*/
create view ref_drug_mapping as
select lower(drug_name) drug_name, modality, moa
from drug_mapping_cat_expn9
;

drop table if exists _drug_alias_plus cascade;
create table _drug_alias_plus as
with dav as ( -- renaming the field names
    select lower(generic_name) drug_name, btrim(trade_name) alias
    from ref_drug_alias_v3
), dae as ( -- renaming the field names
    select lower(drug_name) drug_name, btrim(other_names) alias
    from drug_alias_expn9
)
select drug_name, alias from dav where alias !='' union --quickfix
select drug_name, alias from dae where alias !='' union --quickfix
select drug_name, drug_name from ref_drug_mapping union --quickfix
select drug_name, drug_name from dav
;
-- select * from _drug_alias_plus order by drug_name, alias limit 99;

drop table if exists _rx_drug cascade;
create table _rx_drug as
with rx as ( -- unique rx_names
    select distinct rx_name from viecure_ct.all_rx
)
select distinct rx_name, drug_name
from rx
join _drug_alias_plus
on ct.py_contains(rx_name, '\\b'+alias+'\\b', 'i')
;
-- select * from _rx_drug order by drug_name, rx_name limit 99;

create or replace view _rx_drug_annotating as
with da as (
    select drug_name, listagg(distinct alias, '| ') within group (order by alias) as aliases
    from _drug_alias_plus
    group by drug_name
)
select rx_name, drug_name, aliases, null::bool is_valid
from _rx_drug
join da using (drug_name)
order by drug_name, rx_name
;
-- select * from _rx_drug_annotating order by drug_name, rx_name limit 99;
