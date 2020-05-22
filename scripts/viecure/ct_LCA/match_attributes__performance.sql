/*** match 
Requires: demo (date_of_birth)
, crit_attribute_used (attribute_id)
Result: _pa_performance
*/
set search_path to ct_LCA;
CREATE TABLE _p_a_performance AS
SELECT person_id, attribute_id, 
CASE code_ext
	WHEN 'eq' then score = attribute_value
	END AS MATCH
FROM viecure_ct.assessment a
JOIN crit_attribute_used on code = lower(assessment_type)
JOIN cohort using(person_id)

select (*)
FROM cohort
JOIN viecure_ct.assessment using(person_id)
WHERE lower(assessment_type) = 'ecog' or lower(assessment_type) = 'karnofsky'
;

create view qc_match_performance as
with cau as (
    select * from crit_attribute_used
    where code in ('ecog', 'karnofsky')
), matched as (
    SELECT attribute_id
    , count(distinct person_id) as patients
    from _p_a_performance
    where match
    group by attribute_id
)
select attribute_id, attribute_name, attribute_value
, nvl(patients, 0) matched_patients
from cau
left join matched using (attribute_id)
order by attribute_id
;
select * from qc_match_performance;
