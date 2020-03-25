select distinct medical_record_number
from d_person
join fact using (person_id)
join b_diagnosis using (diagnosis_group_key)
join fd_diagnosis using (diagnosis_key)
where context_name like 'ICD%'
    and context_diagnosis_code ~ '^(K5[0-2]|55[5-8]|M32|710[.]?0)'
;

