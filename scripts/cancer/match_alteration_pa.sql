
/******
* match mutations: to be improved using bool_or
* require: gene_alterrations_pivot
*/
create table gene_alterations_pivot as
select person_id
, max(case when gene='EGFR' then alterations end) as EGFR
, max(case when gene='KRAS' then alterations end) as KRAS
, max(case when gene='BRAF' then alterations end) as BRAF
, max(case when gene='ERBB2' then alterations end) as ERBB2
, max(case when gene='MET' then alterations end) as MET
, max(case when gene='ALK' then alterations end) as ALK
, max(case when gene='ROS' then alterations end) as ROS1 --fixed
, max(case when gene='RET' then alterations end) as RET
, max(case when gene='TP53' then alterations end) as TP53
, max(case when gene='SMO' then alterations end) as SMO
, max(case when gene='PTCH1' then alterations end) as PTCH1
from gene_alterations
group by person_id
;

--select count(*) from gene_alterations;
    --1451
drop table if exists _p_a_mutation cascade;
create table _p_a_mutation as
select person_id, '' as patient_value
, attribute_id
, case attribute_id --attribute_name || ', ' || value 
    when 95 then lower(egfr) ~ 'exon 19 del|l858r|t790' --activating
    when 96 then lower(egfr) ~ 'exon 19 del'
    when 97 then lower(egfr) ~ 'l858r'
    when 98 then lower(egfr) ~ 't790m'
    when 99 then lower(egfr) ~ 'amplification'
    when 100 then lower(egfr) ~ 'exon 20 ins'
    when 101 then lower(alk) ~ 'fusion'
    when 102 then lower(alk) ~ 'alk.+eml4'
    when 104 then met is not NULL
    when 106 then lower(ros1) ~ 'fusion'
    when 108 then ret is not NULL
    when 110 then braf is not NULL
    when 111 then braf ~ 'p.V600\\D'
    when 113 then kras is not NULL
    when 114 then kras ~ 'p.G12\\D|Codon 12 ' --hotspot
    when 116 then erbb2 is not NULL
    when 118 then tp53 is not NULL
    when 220 then smo is not NULL
    when 222 then ptch1 is not NULL
    end as match
from gene_alterations_pivot
cross join crit_attribute
where lower(attribute_group)='mutation'
;
/*qc
select attribute_name, value, count(distinct person_id)
from _p_a_mutation pa join crit_attribute using (attribute_id)
where match
group by attribute_name, value
order by attribute_name, value
;
*/
