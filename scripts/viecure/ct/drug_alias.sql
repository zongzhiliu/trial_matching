/* > drug_alias_plus, _rx_drug, rx_drug_annotating
Input: drug_mapping_cat_expn_v9, drug_alias_expn_v9, ref_drug_alias_v3
*/
-- drug_alias need to cover all of drug_mapping
-- drug_names needed for convenience of qc
create table _drug_alias_plus as
with da as ( -- renaming the field names
    select lower(generic_name) drug_name, btrim(trade_name) alias
    from ref_drug_alias_v3
)
select drug_name, btrim(alias) from da union
select drug_name, btrim(alias) from drug_alias_expn_v9 union
select drug_name, drug_name from drug_alias_expn_v9 union
select drug_name, drug_name from da
;

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

create view _rx_drug_annotating as
with da as (
    select drug_name, listagg(distinct alias, '| ') within group (order by alias) as aliases
    from _drug_alias_plus
    group by drug_name
)
select rx_name, drug_name, aliases, null:bool is_valid
from _rx_drug
join da using (drug_name)
order by drug_name, rx_name
;
