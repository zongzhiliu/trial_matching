/**** match labs
Result: _p_a_test
Require: cohort, ct.latest_test, ct.ref_test
, ct.latest_icd
*/
--drop table _latest_test_normal_range;
CREATE temporary TABLE _latest_test_normal_range AS
SELECT ct_test_name, loinc_code
, normal_low, normal_high
, person_id
, test_time result_date
, value_float
from cohort
join ct.latest_test using (person_id)
join ct.ref_test using (ct_test_name)
;

create temporary table _como as
    select person_id
    , nvl(bool_or(icd_code ~ '^(C78[.]7|197[.]7)'), False) as livermet
    , nvl(bool_or(icd_code ~ '^(E80[.]4|277[.]4)'), False) as gs
    from cohort
    join ct.latest_icd using (person_id)
    group by person_id
;

-- improve with mapping table integrated with attribute id
drop table if exists _p_a_test cascade;
create table _p_a_test as
select person_id, '' as patient_value
, attribute_id
, bool_or(case attribute_id
    --when 48 then --adequate organ function NULL
    --AST<=1 xULN
    when 49 then decode(ct_test_name='AST', True, value_float/normal_high <=1)
    when 50 then decode(ct_test_name='AST', True, value_float/normal_high <=1.5)
    when 51 then decode(ct_test_name='AST', True, value_float/normal_high <=2)
    when 52 then decode(ct_test_name='AST', True, value_float/normal_high <=2.5)
    when 53 then decode(ct_test_name='AST', True, value_float/normal_high <=3)
    when 54 then decode(ct_test_name='AST', True, value_float/normal_high <=5)
            and livermet
    --ALT<=1 xULN
    when 56 then decode(ct_test_name='ALT', True, value_float/normal_high <=1)
    when 57 then decode(ct_test_name='ALT', True, value_float/normal_high <=1.5)
    when 58 then decode(ct_test_name='ALT', True, value_float/normal_high <=2)
    when 59 then decode(ct_test_name='ALT', True, value_float/normal_high <=2.5)
    when 60 then decode(ct_test_name='ALT', True, value_float/normal_high <=3)
    when 61 then decode(ct_test_name='ALT', True, value_float/normal_high <=5)
            and livermet
    --total bilirubin
    when 63 then decode(ct_test_name='Total bilirubin', True, value_float/normal_high <=1)
    when 64 then decode(ct_test_name='Total bilirubin', True, value_float/normal_high <=1.5)
    when 65 then decode(ct_test_name='Total bilirubin', True, value_float/normal_high <=2)
    when 66 then decode(ct_test_name='Total bilirubin', True, value_float/normal_high <=2.5)
    when 67 then decode(ct_test_name='Total bilirubin', True, value_float/normal_high <=3)
            and gs
    --direct bilirubin
    when 69 then decode(ct_test_name='Direct bilirubin', True, value_float/normal_high <=1)
    when 70 then decode(ct_test_name='Direct bilirubin', True, value_float/normal_high <=1.5)
    --Serum Creatinine xULN
    when 72 then decode(ct_test_name='Serum creatinine', True, value_float/normal_high <=1)
    when 73 then decode(ct_test_name='Serum creatinine', True, value_float/normal_high <=1.5)
    when 74 then decode(ct_test_name='Serum creatinine', True, value_float/normal_high <=2)
    -- CrCL ml/min
    when 76 then decode(ct_test_name='CrCl', True, value_float>=30)
    when 77 then decode(ct_test_name='CrCl', True, value_float>=40)
    when 78 then decode(ct_test_name='CrCl', True, value_float>=45)
    when 79 then decode(ct_test_name='CrCl', True, value_float>=50)
    when 80 then decode(ct_test_name='CrCl', True, value_float>=60)
    --Platelets >=50,000 cells/ul; lab values not converted to be fixed
    when 82 then decode(ct_test_name = 'Platelets', True, value_float>=50)
    when 83 then decode(ct_test_name = 'Platelets', True, value_float>=75)
    when 84 then decode(ct_test_name = 'Platelets', True, value_float>=100)
    when 290 then decode(ct_test_name = 'Platelets', True, value_float>=150)
    --ANC  >=750 cells/ul; value_float 10^3 cells/ul
    when 86 then decode(ct_test_name = 'ANC', True, value_float>=0.75)
    when 87 then decode(ct_test_name = 'ANC', True, value_float>=1)
    when 88 then decode(ct_test_name = 'ANC', True, value_float>=1.5)
    --Hemoglobin g/dL
    when 90 then decode(ct_test_name = 'Hemoglobin', True, value_float>=8)
    when 91 then decode(ct_test_name = 'Hemoglobin', True, value_float>=8.5)
    when 92 then decode(ct_test_name = 'Hemoglobin', True, value_float>=9)
    when 93 then decode(ct_test_name = 'Hemoglobin', True, value_float>=10)
    when 94 then decode(ct_test_name = 'Hemoglobin', True, value_float>=11)
    when 418 then decode(ct_test_name = 'Hemoglobin', True, value_float>=9.5)
    --HemoglobinA1C %
    when 274 then decode(ct_test_name='HemoglobinA1c', True, value_float<=8.5)
    when 275 then decode(ct_test_name='HemoglobinA1c', True, value_float<=9)
    when 276 then decode(ct_test_name='HemoglobinA1c', True, value_float<=9.5)
    when 277 then decode(ct_test_name='HemoglobinA1c', True, value_float<=10)
    -- INR xULN
    when 278 then decode(ct_test_name='INR', True, value_float/normal_high>1.3)
    when 279 then decode(ct_test_name='INR', True, value_float/normal_high>1.4)
    when 280 then decode(ct_test_name='INR', True, value_float/normal_high>1.5)
    when 417 then decode(ct_test_name='INR', True, value_float/normal_high<=1.5)
    --Lab eGFR>=ml/min
    when 281 then decode(ct_test_name='eGFR', True, value_float>=30)
    when 413 then decode(ct_test_name='eGFR', True, value_float>=35)
    when 412 then decode(ct_test_name='eGFR', True, value_float>=45)
    when 282 then decode(ct_test_name='eGFR', True, value_float>=50)
    when 283 then decode(ct_test_name='eGFR', True, value_float>=60)
    when 284 then decode(ct_test_name='eGFR', True, value_float>=90)
    -- Albumin g/dL, xLLN
    when 287 then decode(ct_test_name='Serum albumin', True, value_float>2.5)
    when 414 then decode(ct_test_name='Serum albumin', True, value_float>3.0)
    when 415 then decode(ct_test_name='Serum albumin', True, value_float>2.8)
    when 288 then decode(ct_test_name='Serum albumin', True, value_float/normal_low<=1)
    -- WBC x10^3 cells/ul
    when 317 then decode(ct_test_name='WBC', True, value_float>=2.0)
    when 318 then decode(ct_test_name='WBC', True, value_float>=2.5)
    when 319 then decode(ct_test_name='WBC', True, value_float>=3.0)
    when 320 then decode(ct_test_name='WBC', True, value_float>=3.5)
    -- hematocrit xULN -- typo fixed here
    when 289 then decode(ct_test_name='Hematocrit', True, value_float/normal_high<=1)
    -- Alkaline phosphatase xULN
    when 291 then decode(ct_test_name='Alkaline phosphatase', True, value_float/normal_high<=2)
    -- PAS mg/ml -- Fixme: not in mapping (patient_activity_score)
    -- when 292 then decode(ct_test_name='PAS', True, value_float<=4)
    -- Prolactin xULN
    when 293 then decode(ct_test_name='Prolactin', True, value_float/normal_high<=1)
    -- Serum lipase xULN
    when 302 then decode(ct_test_name='Serum lipase', True, value_float/normal_high<=1)
    -- Serum amylase xULN
    when 303 then decode(ct_test_name='Serum amylase', True, value_float/normal_high<=1)
    -- Potasium mmol/L  -- Checkme: uom not in mapping mmol/L?
    when 416 then decode(ct_test_name='Potassium', True, value_float>=3.5)
    -- FPG (fasting glucose) mg/dl
    when 304 then decode(ct_test_name='FPG', True, value_float between 100 and 240)
    end) as match
from (crit_attribute_used cross join _latest_test_normal_range)
left join _como using (person_id)
where attribute_id in ( 49, 50, 51, 52, 53, 54, 56, 57, 58, 59, 60, 61, 63, 64,
    65, 66, 67, 69, 70, 72, 73, 74, 76, 77, 78, 79, 80, 82, 83, 84, 290, 86, 87,
    88, 90, 91, 92, 93, 94, 418, 274, 275, 276, 277, 281, 413, 282, 283, 284, 412,
    278, 279, 280, 417, 287, 414, 415, 288, 317, 318, 319, 320, 289, 291, 293,
    302, 303, 416, 304)
group by attribute_id, person_id
;
create view qc_test as
with tmp as (
    select attribute_id, attribute_name, attribute_value, match
    , count(distinct person_id)
    from _p_a_test join crit_attribute_used using (attribute_id)
    group by attribute_id, attribute_name, attribute_value, match
)
select attribute_id, attribute_name, attribute_value
, max(case when match is true then count end) patients_true
, max(case when match is false then count end) patients_false
, max(case when match is null then count end) patients_null
from tmp
group by attribute_id, attribute_name, attribute_value
order by attribute_name, attribute_value
;
select * from qc_test;

/* no vitals for lca, do it later
 Require: vital, vital_bmi
 Result: _p_a_t_weight, _p_a_t_blood_pressure

drop table if exists _p_a_t_weight cascade;
create table _p_a_t_weight as
select attribute_id, trial_id, person_id
, ie_value::float as value
, weight_kg::float as patient_value
, case attribute_id
    when 301 --'max_body weight'
        then patient_value<=value
    when 300 --'min_body weight'
        then patient_value>=value
    end as match
from trial_attribute_used
cross join _latest_bmi
where attribute_id in (300, 301)
;
create view qc_match_weight as
select attribute_name, attribute_value, value
, count(distinct person_id)
from _p_a_t_weight join crit_attribute_used using (attribute_id)
where match
group by attribute_name, attribute_value, value
order by attribute_name, attribute_value, value
;

drop table if exists _p_a_t_blood_pressure cascade;
create table _p_a_t_blood_pressure as
select attribute_id, trial_id, person_id
, ie_value::int value
, case attribute_id
    when 268 then systolic::int --max
    when 269 then diastolic::int --max
    end as patient_value
, patient_value<=value as match
from trial_attribute_used t
join crit_attribute_used a using (attribute_id)
cross join _latest_blood_pressure p
where attribute_id in (268, 269)
--    and nvl(inclusion, exclusion) ~ '^[0-9]+$' --Fixme
;
create view qc_match_blood_pressure as
select attribute_name, attribute_value, value, count(distinct person_id)
from _p_a_t_blood_pressure join crit_attribute_used using (attribute_id)
where match
group by attribute_name, attribute_value, value
order by attribute_name, attribute_value, value
;
--select * from qc_match_blood_pressure;
--select * from qc_match_weight;
*/
