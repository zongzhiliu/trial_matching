drop table if exists _p_a_rxnorm cascade;
create table _p_a_rxnorm as
SELECT r.mrn, attribute_id,
case code_type
	when 'drug_name' then bool_or(drug_name=code)
    when 'drug_modality_rex' then bool_or(modality=lower(code))
    when 'drug_moa_rex' then bool_or(ct.py_contains(moa, code, 'i'))
	when 'drug_moa_rex_le_tempo' then bool_or(ct.py_contains(moa, code, 'i'))
    end as match
FROM rx r
JOIN _all_name an using(rx_name)
LEFT JOIN ct.drug_mapping_cat_expn6 mp using (drug_name)
JOIN crit_attribute_used cau on code_type in ('drug_name', 'drug_moa_rex',
    'drug_modality_rex')
GROUP BY mrn, attribute_id, code_type;

drop table if exists latest_rx;
create table latest_rx as
select mrn person_id
, drug_name, moa, modality
, dateadd(day, age_in_days, date_of_birth)::date rx_date
from (select *, row_number() over (
        partition by mrn, drug_name
        order by -age_in_days)
    FROM rx
    join demo using (mrn)
    JOIN _all_name an using(rx_name)
    JOIN ct.drug_mapping_cat_expn6 mp using (drug_name))
where row_number=1
;
/*
select count(*), count(distinct person_id) from lastest_rx;
select * from lastest_rx limit 99;
*/

drop table if exists _p_a_drug_moa_le_tempo cascade;
create table _p_a_drug_moa_le_tempo as
with cau as (
    select attribute_id, code, code_transform::float max_years
    from crit_attribute_used
    where code_type = 'drug_moa_rex_le_tempo'
)
select person_id, attribute_id
, True as match
from latest_rx join cau on ct.py_contains(moa, code)
    and datediff(day, rx_date, current_date)/365.25 <= 3 --max_years
group by person_id, attribute_id
;

drop view if exists _p_a_t_rxnorm;
create view _p_a_t_rxnorm as
with cau as (
    select attribute_id
    from crit_attribute_used
    where code_type in ('drug_name', 'drug_moa_rex', 'drug_moa_rex_le_tempo',
        'drug_modality_rex')
), pa as (
    select mrn person_id, attribute_id, match from _p_a_rxnorm union all
    select person_id, attribute_id, match from _p_a_drug_moa_le_tempo
)
select person_id, trial_id, attribute_id
, nvl(match, False) as match
from (cohort cross join cau)
left join pa using (person_id, attribute_id)
join trial_attribute_used using (attribute_id)
;
/*
with tmp as (
    select attribute_id, attribute_name, attribute_value, code_type
    , match, count(distinct person_id) patients
    --from _p_a_rxnorm join cohort using (mrn) join crit_attribute_used using (attribute_id)
    from _p_a_t_rxnorm join cohort using (person_id) join crit_attribute_used using (attribute_id)
    group by attribute_id, attribute_name, attribute_value, match, code_type
)
select attribute_id, attribute_name, attribute_value, code_type
, sum(case when match is True then patients end) as True_patients
, sum(case when match is False then patients end) as false_patients
from tmp
group by attribute_id, attribute_name, attribute_value, code_type
order by attribute_id, attribute_name, attribute_value
;
*/
