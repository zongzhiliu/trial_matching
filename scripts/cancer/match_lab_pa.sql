--set search_path=ct_${cancer_type};

/****
* match labs
* require: latest_lab, ref_lab_mapping
*/
--drop table _latest_lab_normal_range;
CREATE temporary TABLE _latest_lab_normal_range AS
SELECT lab_test_name, loinc_code, m.unit, source_unit
, normal_low, normal_high
, person_id
, result_date, value_float
from latest_lab
join ref_lab_mapping m using (loinc_code) --{ref_lab}
;

create temporary table _como as
    select person_id
    , bool_or(icd_code ~ '^(C787[.]7|197[.]7)') as livermet
    , bool_or(icd_code ~ '^(E80[.]4|277[.]4)') as gs
    from latest_icd
    group by person_id
;

-- improve with mapping table integrated with attribute id
drop table if exists _p_a_lab;
create table _p_a_lab as
select person_id, '' as patient_value
, attribute_id
, bool_or(case attribute_id
    --when 48 then --adequate organ function NULL
    when 49 then --AST<=1 xULN
        lab_test_name='AST' and value_float/normal_high <=1
    when 50 then lab_test_name='AST' and value_float/normal_high <=1.5
    when 51 then lab_test_name='AST' and value_float/normal_high <=2
    when 52 then lab_test_name='AST' and value_float/normal_high <=2.5
    when 53 then lab_test_name='AST' and value_float/normal_high <=3
    when 54 then lab_test_name='AST' and value_float/normal_high <=5
            and nvl(livermet, False)
    when 56 then --ALT<=1 xULN
        lab_test_name='ALT' and value_float/normal_high <=1
    when 57 then lab_test_name='ALT' and value_float/normal_high <=1.5
    when 58 then lab_test_name='ALT' and value_float/normal_high <=2
    when 59 then lab_test_name='ALT' and value_float/normal_high <=2.5
    when 60 then lab_test_name='ALT' and value_float/normal_high <=3
    when 61 then lab_test_name='ALT' and value_float/normal_high <=5
            and nvl(livermet,False)
    when 63 then --total bilirubin
        lab_test_name='Total bilirubin' and value_float/normal_high <=1
    when 64 then lab_test_name='Total bilirubin' and value_float/normal_high <=1.5
    when 65 then lab_test_name='Total bilirubin' and value_float/normal_high <=2
    when 66 then lab_test_name='Total bilirubin' and value_float/normal_high <=2.5
    when 67 then lab_test_name='Total bilirubin' and value_float/normal_high <=3
            and nvl(gs, False)
    when 69 then --direct bilirubin
        lab_test_name='Direct bilirubin' and value_float/normal_high <=1
    when 70 then lab_test_name='Direct bilirubin' and value_float/normal_high <=1.5
    when 72 then --Serum Creatinine
        lab_test_name='Serum Creatinine' and value_float/normal_high <=1
    when 73 then lab_test_name='Serum Creatinine' and value_float/normal_high <=1.5
    when 74 then lab_test_name='Serum Creatinine' and value_float/normal_high <=2
    when 76 then -- CrCL check unit conversion later
        lab_test_name ilike 'CrCl' and value_float>=30
    when 77 then lab_test_name ilike 'CrCl' and value_float>=40
    when 78 then lab_test_name ilike 'CrCl' and value_float>=45
    when 79 then lab_test_name ilike 'CrCl' and value_float>=50
    when 80 then lab_test_name ilike 'CrCl' and value_float>=60
    when 82 then --Platelets    >=50,000 cells/ul; lab values not converted to be fixed
        lab_test_name = 'Platelets' and value_float>=50
    when 83 then lab_test_name = 'Platelets' and value_float>=75
    when 84 then lab_test_name = 'Platelets' and value_float>=100
    when 290 then lab_test_name = 'Platelets' and value_float>=150
    when 86 then --ANC    >=750 cells/ul; value_float 10^3 cells/ul
        lab_test_name = 'ANC' and value_float>=0.75
    when 87 then lab_test_name = 'ANC' and value_float>=1
    when 88 then lab_test_name = 'ANC' and value_float>=1.5
    when 90 then --Hemoglobin g/dL
        lab_test_name = 'Hemoglobin' and value_float>=8
    when 91 then lab_test_name = 'Hemoglobin' and value_float>=8.5
    when 92 then lab_test_name = 'Hemoglobin' and value_float>=9
    when 93 then lab_test_name = 'Hemoglobin' and value_float>=10
    when 94 then lab_test_name = 'Hemoglobin' and value_float>=11
    when 418 then lab_test_name = 'Hemoglobin' and value_float>=9.5
    when 274 then --HemoglobinA1C %
        lab_test_name='HemoglobinA1c' and value_float<=8.5
    when 275 then lab_test_name='HemoglobinA1c' and value_float<=9
    when 276 then lab_test_name='HemoglobinA1c' and value_float<=9.5
    when 277 then lab_test_name='HemoglobinA1c' and value_float<=10
    when 281 then --Lab eGFR>=30 
        lab_test_name='eGFR' and value_float>=30
    when 413 then lab_test_name='eGFR' and value_float>=35
    when 282 then lab_test_name='eGFR' and value_float>=50
    when 283 then lab_test_name='eGFR' and value_float>=60
    when 284 then lab_test_name='eGFR' and value_float>=90
    when 412 then lab_test_name='eGFR' and value_float>=45
    when 278 then lab_test_name='INR' and value_float/normal_high>1.3
    when 279 then lab_test_name='INR' and value_float/normal_high>1.4
    when 280 then lab_test_name='INR' and value_float/normal_high>1.5
    when 417 then lab_test_name='INR' and value_float/normal_high<=1.5
    -- Albumin g/dL
    when 287 then lab_test_name='Serum albumin' and value_float>2.5
    when 414 then lab_test_name='Serum albumin' and value_float>3.0
    when 415 then lab_test_name='Serum albumin' and value_float>2.8
    -- Albumin xLLN
    when 288 then lab_test_name='Serum albumin' and value_float/normal_low<=1
    -- WBC x10^3 cells/ul
    when 317 then lab_test_name='WBC' and value_float>=2.0
    when 318 then lab_test_name='WBC' and value_float>=2.5
    when 319 then lab_test_name='WBC' and value_float>=3.0
    when 320 then lab_test_name='WBC' and value_float>=3.5
    when 289 then lab_test_name='Hamatocrit' and value_float/normal_high<=1 --x ULN
    when 291 then lab_test_name='Alkaline phosphatase' and value_float/normal_high<=2 --xUNL
    when 292 then lab_test_name='PAS' and value_float<=4) -- mg/ml
    when 293 then lab_test_name='Prolactin' and value_float/normal_high<=1 --x ULN
    when 302 then lab_test_name='Serum lipase' and value_float/normal_high<=1 --x ULN
    when 303 then lab_test_name='Serum amylase' and value_float/normal_high<=1 --x ULN
    when 416 then lab_test_name='Potasium' and value_float>=3.5 -- mmol/L
    when 304 then lab_test_name='FPG' and value_float between 100 and 240 --mg/dL
    end) as match
from (crit_attribute_used cross join _latest_lab_normal_range)
left join _como using (person_id)
--where lower(attribute_group)~'labs?'
--   and lower(attribute_value) not in ('min', 'max')
where attribute_id in ( 49, 50, 51, 52, 53, 54, 56, 57, 58, 59, 60, 61, 63, 64,
    65, 66, 67, 69, 70, 72, 73, 74, 76, 77, 78, 79, 80, 82, 83, 84, 290, 86, 87,
    88, 90, 91, 92, 93, 94, 418, 274, 275, 276, 277, 281, 413, 282, 283, 284, 412,
    278, 279, 280, 417, 287, 414, 415, 288, 317, 318, 319, 320, 289, 291, 292, 293,
    302, 303, 416, 304)
group by attribute_id, person_id
;

/*qc
select attribute_name, value, count(distinct person_id)
from _p_a_lab join crit_attribute_used_raw using (attribute_id)
where match
group by attribute_name, value
order by attribute_name, value
;
*/


