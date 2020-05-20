set search_path to viecure_ct;
CREATE TABLE assessment as 
SELECT patient_id person_id, description assessment_type
	, score, assessment_date 
FROM viecure_emr.patient_questionnaire_response_hdr pqrh 
JOIN viecure_emr.assessment_list al on assessment_list_id = al.id
WHERE NOT nvl(errored, FALSE)
;
