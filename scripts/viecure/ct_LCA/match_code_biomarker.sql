create temporary table _biomarker_pd as
select person_id
, gene_name protein_biomarker_name
, decode(pd_result
	, 'Low', 'Low positive'
	, 'Medium', 'Low positive'
	, pd_result) interpretation
, pd_tumor_score_percent/100.0 positive_cell_pct
from viecure_ct.all_gene_alteration
where gene_name='PD-L1';

drop table if exists _p_a_biomarker cascade;
CREATE TABLE _p_a_biomarker as
with cau as (
    SELECT attribute_id, attribute_value, code_type, code
    from crit_attribute_used
    WHERE code_type = 'protein_biomarker'
), b as (
    select *
    from _biomarker_pd
    join cohort using (person_id)
)
SELECT person_id, attribute_id
, bool_or(case lower(attribute_value)
    when 'yes' THEN interpretation ilike '%positive%'
    else positive_cell_pct * 100 >= regexp_substr(attribute_value, '[0-9]+')::int
    end) as match
from b
join cau on b.protein_biomarker_name=cau.code
group by person_id, attribute_id
;

create view qc_match_biomarker as
select attribute_id, attribute_name, attribute_value
, count(distinct person_id)
from _p_a_biomarker join crit_attribute_used using (attribute_id)
where match
group by attribute_id, attribute_name, attribute_value
order by attribute_id, attribute_name, attribute_value
;
select * from qc_match_biomarker;
