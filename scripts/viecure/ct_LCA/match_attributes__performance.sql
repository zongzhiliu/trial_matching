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