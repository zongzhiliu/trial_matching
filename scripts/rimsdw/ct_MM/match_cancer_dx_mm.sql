/***
Result: _p_a_t_mm_cancer_dx
Input: cplus_from_aplus.cancer_diagnosis_mm.m_protein_type
*/
drop table if exists _p_a_t_mm_cancer_dx cascade;
create table _p_a_t_mm_cancer_dx as
with tau as (
    select attribute_id, trial_id
    , attribute_value
    , code, code_ext
    from trial_attribute_used
    join crit_attribute_used using (attribute_id)
    where code_type = 'mm_cancer_dx' -- and code='m_protein_type'
), cdx as (
    select * --person_id, m_protein_type
    from cplus_from_aplus.cancer_diagnoses_mm
    join cplus_from_aplus.cancer_diagnoses using (cancer_diagnosis_id)
    join cohort using(person_id)
)
select person_id, trial_id, attribute_id
, bool_or(case code
    when 'mm_active_status' then
        mm_active_status=code_ext
    when 'm_protein_type' then
        m_protein_type=code_ext
    when 'BMPCs' then
        case code_ext
            when 'min' then nvl(plasma_cell_pct_biopsy_low, plasma_cell_pct_aspirate_low) --src_value
                >= regexp_substr(attribute_value, '[0-9]+')::int --crit_value
            when 'max' then nvl(plasma_cell_pct_biopsy_high, plasma_cell_pct_aspirate_high) --src_value
                <= regexp_substr(attribute_value, '[0-9]+')::int --crit_value
        end
    end) as match
from tau
cross join cdx
group by person_id, trial_id, attribute_id
;

create view qc_mm_cancer_dx as
select attribute_id, attribute_name, attribute_value
, count(distinct person_id)
from _p_a_t_mm_cancer_dx
join crit_attribute_used using (attribute_id)
where match
group by attribute_id, attribute_name, attribute_value
;
select * from qc_mm_cancer_dx;
