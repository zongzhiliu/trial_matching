CREATE view _lab_w_normal_range AS
SELECT person_id, lab_test_name, loinc_code, m.unit
, normal_low, normal_high
, result_date, value_float
from cohort join latest_lab using (person_id)
--join ${ref_lab_mapping} m using (loinc_code)
join ref_lab_mapping m using (loinc_code)
;

