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
create table _drug_alias_cat as (
    select drug_name, listagg(distinct alias, '| ') within group (order by alias) as aliases
    from _drug_alias_plus
    group by drug_name
);

