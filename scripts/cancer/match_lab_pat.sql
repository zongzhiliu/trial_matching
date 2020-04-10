--set search_path=ct_${cancer_type};

-- lab min/max
drop table if exists _p_a_t_lab;
create table _p_a_t_lab as
select attribute_id, trial_id, person_id
, '' as patient_value
, nvl(inclusion, exclusion) as clusion
, case attribute_id
    when 409 --'testosteron Min
        then bool_or(loinc_code='49041-7' and value_float>=clusion::float)
    when 384 --'testosteron Max
        then bool_or(loinc_code='49041-7' and value_float<=clusion::float)
    end as match
from trial_attribute_used
join crit_attribute_used using (attribute_id)
cross join latest_lab
--where attribute_id in (409, 384, 386, 387)
where lower(attribute_group)~'labs?'
    and lower(attribute_value) in ('min', 'max')
--    and nvl(inclusion, exclusion) ~ '^[0-9]+([.][0-9]+)?$' --Fixme
group by attribute_id, person_id, trial_id, inclusion, exclusion
;
/*-- check
select * from _p_a_t_lab
order by person_id, trial_id, attribute_id
limit 10
;
select attribute_name, attribute_value, clusion
, count(distinct person_id) patients, count(distinct trial_id) trials
from _p_a_t_lab join crit_attribute_used using (attribute_id)
where match
group by attribute_name, attribute_value, clusion
order by attribute_name, attribute_value, clusion::int
;
*/
