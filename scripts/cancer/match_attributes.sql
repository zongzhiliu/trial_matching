/***
Requires:
    trial_attribute_used
    crit_attribute_used
    ref_drug_mapping
    ref_lab_mapping

    demo, stage, histology
    latest_loh_drug
    latest_ecog, latest_karnofsky
    latest_lab, latest_icd
    vital, vital_bmi
    gene_alterations_pivot
Results:
    _master_match
Settings:
    @set cancer_type=
    @set cancer_type_icd=
*/
set search_path=ct_${cancer_type};


/***
 * match stage, status: multiple sele
 */
drop table if exists _p_a_stage;
create table _p_a_stage as
select person_id, stage as patient_value
, attribute_id
, case value
     when '0' then stage_base='0'
     when 'I' then stage_base='I'
     when 'IA' then stage_base='I' and stage_ext like 'A%'
     when 'IB' then stage_base='I' and stage_ext like 'B%'
     when 'II' then stage_base='II'
     when 'IIA' then stage_base='II' and stage_ext like 'A%'
     when 'IIB' then stage_base='II' and stage_ext like 'B%'
     when 'IIC' then stage_base='II' and stage_ext like 'C%'
     when 'III' then stage_base='III'
     when 'IIIA' then stage_base='III' and stage_ext like 'A%'
     when 'IIIB' then stage_base='III' and stage_ext like 'B%'
     when 'IIIC' then stage_base='III' and stage_ext like 'C%'
     when 'IV' then stage_base='IV'
     when 'IVA' then stage_base='IV' and stage_ext like 'A%'
     when 'IVB' then stage_base='IV' and stage_ext like 'B%'
     when 'limited stage' then stage_base between 'I' and 'III'
     when 'extensive stage' then stage_base = 'IV'
     end as match
from stage
cross join crit_attribute_used
where attribute_name='stage'
;
/*-- check
select attribute_name, value, count(*)
from _p_a_stage join crit_attribute_used using (attribute_id)
where match
group by attribute_name, value
order by attribute_name, value
;
*/

/***
* match demographics
*/
drop table if exists _p_a_t_age;
create table _p_a_t_age as
select attribute_id, trial_id, person_id
, (datediff(day, date_of_birth, current_date)/365.25)::int as patient_value
, nvl(inclusion, exclusion) as clusion
, case attribute_id
    when 205 --'Min_age
        then patient_value>=clusion::int
    when 206 --'Max_age
        then patient_value<=clusion::int
    end as match
from trial_attribute_used
join crit_attribute_used using (attribute_id)
cross join demo
where attribute_id in (205, 206)
    and nvl(inclusion, exclusion) ~ '^[0-9]+$'
;
/*-- check
select attribute_name, value, clusion, count(distinct person_id)
from _p_a_t_age join crit_attribute_used using (attribute_id)
where match
group by attribute_name, value, clusion
order by attribute_name, value, clusion::int
;

/***
* match performance
*/
-- ecog from latest_ecog
drop table if exists _p_a_ecog;
create table _p_a_ecog as
select person_id, ecog_ps as patient_value
, attribute_id
, patient_value=value::int as match
from latest_ecog
cross join crit_attribute_used
where lower(attribute_name)='ecog'
;
--select * from _p_a_ecog;
/*-- check
select attribute_name, value, count(*)
--select patient_value
from _p_a_ecog join ct.crit_attribute using (attribute_id)
where match
group by attribute_name, value
;
*/

-- karnofsky
drop table if exists _p_a_karnofsky;
create table _p_a_karnofsky as
select person_id, karnofsky_pct as patient_value
, attribute_id
, patient_value=value::int as match
from latest_karnofsky
cross join crit_attribute_used
where lower(attribute_name)='karnofsky'
;

/*-- check
select attribute_name, value, count(*)
from _p_a_karnofsky join crit_attribute_used using (attribute_id)
where match
group by attribute_name, value
;
*/

/***
 * match vital: weight, bmi, bloodpressure
 * require: vital, vital_bmi
 */
drop table if exists _latest_bmi;
create table _latest_bmi as
select person_id, weight_age, weight_kg, height_m, bmi
from (select *, row_number() over (
        partition by person_id
        order by -weight_age, -bmi)
    from vital_bmi
    )
where row_number=1
;
drop table _p_a_t_weight;
create table _p_a_t_weight as
select attribute_id, trial_id, person_id
, nvl(inclusion, exclusion) clusion
, weight_kg::float as patient_value
, case attribute_id
    when 301 --'max_body weight'
        then patient_value<=clusion::float
    when 300 --'min_body weight'
        then patient_value>=clusion::float
    end as match
from trial_attribute_used
cross join _latest_bmi
where attribute_id in (300, 301)
    and nvl(inclusion, exclusion) ~ '^[0-9]+(\\.[0-9]+)?$' --float
;
/*-- check
select attribute_name, value, clusion, count(distinct person_id)
from _p_a_t_weight join crit_attribute_used using (attribute_id)
where match
group by attribute_name, value, clusion
order by attribute_name, value, clusion::int
;
*/
create table _latest_blood_pressure as
with syst as (
    select *, row_number() over (
            partition by person_id
            order by -age_in_days, -value)
    from vital
    where procedure_description='Systolic Blood Pressure'
        and value ~'^[0-9]+(\\.[0-9]+)?$' --float: '152/'
)
, last_syst as (
    select person_id, age_in_days, value as systolic
    from syst where row_number=1
) --select * from last_syst;
, diast as (
    select *, row_number() over (
            partition by person_id
            order by -age_in_days, -value)
    from vital
    where procedure_description='Diastolic Blood Pressure'
        and value ~'^[0-9]+(\\.[0-9]+)?$'  -- debug: invalid digit '/65'
)
, last_diast as (
    select person_id, age_in_days, value as diastolic
    from diast where row_number=1
)
select *
from last_syst
join last_diast using (person_id, age_in_days)
;

drop table _p_a_t_blood_pressure;
create table _p_a_t_blood_pressure as
select attribute_id, trial_id, person_id
, nvl(inclusion, exclusion) clusion
, case attribute_id
    when 268 then systolic::int --max
    when 269 then diastolic::int --max
    end as patient_value
, patient_value<=clusion::int as match
from trial_attribute_used t
join crit_attribute_used a using (attribute_id)
cross join _latest_blood_pressure p
where attribute_id in (268, 269)
    and nvl(inclusion, exclusion) ~ '^[0-9]+$' --int
;
/*-- check
select attribute_name, value, clusion, count(distinct person_id)
from _p_a_t_blood_pressure join crit_attribute_used using (attribute_id)
where match
group by attribute_name, value, clusion
order by attribute_name, value, clusion::int
;
*/

/******
* match mutations: to be improved using bool_or
* require: gene_alterrations_pivot
*/
create table gene_alterations_pivot as
select person_id
, max(case when gene='EGFR' then alterations end) as EGFR
, max(case when gene='KRAS' then alterations end) as KRAS
, max(case when gene='BRAF' then alterations end) as BRAF
, max(case when gene='ERBB2' then alterations end) as ERBB2
, max(case when gene='MET' then alterations end) as MET
, max(case when gene='ALK' then alterations end) as ALK
, max(case when gene='ROS' then alterations end) as ROS1 --fixed
, max(case when gene='RET' then alterations end) as RET
, max(case when gene='TP53' then alterations end) as TP53
, max(case when gene='SMO' then alterations end) as SMO
, max(case when gene='PTCH1' then alterations end) as PTCH1
from gene_alterations
group by person_id
;

--select count(*) from gene_alterations;
    --1451
drop table if exists _p_a_mutation cascade;
create table _p_a_mutation as
select person_id, '' as patient_value
, attribute_id
, case attribute_id --attribute_name || ', ' || value 
    when 95 then lower(egfr) ~ 'exon 19 del|l858r|t790' --activating
    when 96 then lower(egfr) ~ 'exon 19 del'
    when 97 then lower(egfr) ~ 'l858r'
    when 98 then lower(egfr) ~ 't790m'
    when 99 then lower(egfr) ~ 'amplification'
    when 100 then lower(egfr) ~ 'exon 20 ins'
    when 101 then lower(alk) ~ 'fusion'
    when 102 then lower(alk) ~ 'alk.+eml4'
    when 104 then met is not NULL
    when 106 then lower(ros1) ~ 'fusion'
    when 108 then ret is not NULL
    when 110 then braf is not NULL
    when 111 then braf ~ 'p.V600\\D'
    when 113 then kras is not NULL
    when 114 then kras ~ 'p.G12\\D|Codon 12 ' --hotspot
    when 116 then erbb2 is not NULL
    when 118 then tp53 is not NULL
    when 220 then smo is not NULL
    when 222 then ptch1 is not NULL
    end as match
from gene_alterations_pivot
cross join crit_attribute
where lower(attribute_group)='mutation'
;
/*qc
select attribute_name, value, count(distinct person_id)
from _p_a_mutation pa join crit_attribute using (attribute_id)
where match
group by attribute_name, value
order by attribute_name, value
;
*/

/****
* match labs
* require: latest_lab, ref_lab_mapping
*/
drop table _latest_lab_normal_range;
CREATE TABLE _latest_lab_normal_range AS
SELECT lab_test_name, loinc_code, m.unit, source_unit
, normal_low, normal_high
, person_id
, result_date, value_float
from latest_lab
join ref_lab_mapping m using (loinc_code) --{ref_lab}
;

-- improve with mapping table integrated with attribute id
drop table if exists _p_a_lab;
create table _p_a_lab as
select person_id, '' as patient_value
, attribute_id
, case attribute_id
    --when 48 then --adequate organ function NULL
    when 49 then --AST<=1 xULN
        bool_or(lab_test_name='AST' and value_float/normal_high <=1)
    when 50 then bool_or(lab_test_name='AST' and value_float/normal_high <=1.5)
    when 51 then bool_or(lab_test_name='AST' and value_float/normal_high <=2)
    when 52 then bool_or(lab_test_name='AST' and value_float/normal_high <=2.5)
    when 53 then bool_or(lab_test_name='AST' and value_float/normal_high <=3)
    when 54 then bool_or(lab_test_name='AST' and value_float/normal_high <=5)
    when 56 then --ALT<=1 xULN
        bool_or(lab_test_name='ALT' and value_float/normal_high <=1)
    when 57 then bool_or(lab_test_name='ALT' and value_float/normal_high <=1.5)
    when 58 then bool_or(lab_test_name='ALT' and value_float/normal_high <=2)
    when 59 then bool_or(lab_test_name='ALT' and value_float/normal_high <=2.5)
    when 60 then bool_or(lab_test_name='ALT' and value_float/normal_high <=3)
    when 61 then bool_or(lab_test_name='ALT' and value_float/normal_high <=5)
    when 63 then --total bilirubin
        bool_or(lab_test_name='Total bilirubin' and value_float/normal_high <=1)
    when 64 then bool_or(lab_test_name='Total bilirubin' and value_float/normal_high <=1.5)
    when 65 then bool_or(lab_test_name='Total bilirubin' and value_float/normal_high <=2)
    when 66 then bool_or(lab_test_name='Total bilirubin' and value_float/normal_high <=2.5)
    when 67 then bool_or(lab_test_name='Total bilirubin' and value_float/normal_high <=3)
    when 69 then --direct bilirubin
        bool_or(lab_test_name='Direct bilirubin' and value_float/normal_high <=1)
    when 70 then bool_or(lab_test_name='Direct bilirubin' and value_float/normal_high <=1.5)
    when 72 then --Serum Creatinine
        bool_or(lab_test_name='Serum Creatinine' and value_float/normal_high <=1)
    when 73 then bool_or(lab_test_name='Serum Creatinine' and value_float/normal_high <=1.5)
    when 74 then bool_or(lab_test_name='Serum Creatinine' and value_float/normal_high <=2)
    when 76 then -- CrCL check unit conversion later
        bool_or(lab_test_name ilike 'CrCl' and value_float>=30)
    when 77 then bool_or(lab_test_name ilike 'CrCl' and value_float>=40)
    when 78 then bool_or(lab_test_name ilike 'CrCl' and value_float>=45)
    when 79 then bool_or(lab_test_name ilike 'CrCl' and value_float>=50)
    when 80 then bool_or(lab_test_name ilike 'CrCl' and value_float>=60)
    when 82 then --Platelets    >=50,000 cells/ul; lab values not converted to be fixed
        bool_or(lab_test_name = 'Platelets' and value_float>=50)
    when 83 then bool_or(lab_test_name = 'Platelets' and value_float>=75)
    when 84 then bool_or(lab_test_name = 'Platelets' and value_float>=100)
    when 290 then bool_or(lab_test_name = 'Platelets' and value_float>=150)
    when 86 then --ANC    >=750 cells/ul; value_float 10^3 cells/ul
        bool_or(lab_test_name = 'ANC' and value_float>=0.75)
    when 87 then bool_or(lab_test_name = 'ANC' and value_float>=1)
    when 88 then bool_or(lab_test_name = 'ANC' and value_float>=1.5)
    when 90 then --Hemoglobin g/dL
        bool_or(lab_test_name = 'Hemoglobin' and value_float>=8)
    when 91 then bool_or(lab_test_name = 'Hemoglobin' and value_float>=8.5)
    when 92 then bool_or(lab_test_name = 'Hemoglobin' and value_float>=9)
    when 93 then bool_or(lab_test_name = 'Hemoglobin' and value_float>=10)
    when 418 then bool_or(lab_test_name = 'Hemoglobin' and value_float>=9.5)
    when 274 then --HemoglobinA1C %
        bool_or(lab_test_name='HemoglobinA1c' and value_float<=8.5)
    when 275 then bool_or(lab_test_name='HemoglobinA1c' and value_float<=9)
    when 276 then bool_or(lab_test_name='HemoglobinA1c' and value_float<=9.5)
    when 281 then --Lab eGFR>=30 
        bool_or(lab_test_name='eGFR' and value_float>=30)
    when 413 then bool_or(lab_test_name='eGFR' and value_float>=35)
    when 282 then bool_or(lab_test_name='eGFR' and value_float>=50)
    when 283 then bool_or(lab_test_name='eGFR' and value_float>=60)
    when 284 then bool_or(lab_test_name='eGFR' and value_float>=90)
    when 412 then bool_or(lab_test_name='eGFR' and value_float>=45)
    when 278 then bool_or(lab_test_name='INR' and value_float/normal_high>1.3) --x ULN
    when 279 then bool_or(lab_test_name='INR' and value_float/normal_high>1.4)
    when 280 then bool_or(lab_test_name='INR' and value_float/normal_high>1.5)
    when 417 then bool_or(lab_test_name='INR' and value_float/normal_high<=1.5)
    -- Albumin g/dL
    when 287 then bool_or(lab_test_name='Serum albumin' and value_float>2.5) -- g/dL
    when 414 then bool_or(lab_test_name='Serum albumin' and value_float>3.0)
    when 415 then bool_or(lab_test_name='Serum albumin' and value_float>2.8)
    -- Albumin xLLN
    when 288 then bool_or(lab_test_name='Serum albumin' and value_float/normal_low<=1)
    -- WBC x10^3 cells/ul
    when 317 then bool_or(lab_test_name='WBC' and value_float>=2.0)
    when 318 then bool_or(lab_test_name='WBC' and value_float>=2.5)
    when 319 then bool_or(lab_test_name='WBC' and value_float>=3.0)
    when 320 then bool_or(lab_test_name='WBC' and value_float>=3.5)
    when 289 then bool_or(lab_test_name='Hamatocrit' and value_float/normal_high<=1) --x ULN
    when 291 then bool_or(lab_test_name='Alkaline phosphatase' and value_float/normal_high<=2) --xUNL
    when 292 then bool_or(lab_test_name='PAS' and value_float<=4) -- mg/ml
    when 293 then bool_or(lab_test_name='Prolactin' and value_float/normal_high<=1) --x ULN
    when 302 then bool_or(lab_test_name='Serum lipase' and value_float/normal_high<=1) --x ULN
    when 303 then bool_or(lab_test_name='Serum amylase' and value_float/normal_high<=1) --x ULN
    when 416 then bool_or(lab_test_name='Potasium' and value_float>=3.5) -- mmol/L
    when 304 then bool_or(lab_test_name='FPG' and value_float between 100 and 240) --mg/dL
    end as match
from crit_attribute_used
cross join _latest_lab_normal_range
where lower(attribute_group)~'labs?'
group by attribute_id, person_id
;

/*qc
select attribute_name, value, count(distinct person_id)
from _p_a_lab join crit_attribute_used using (attribute_id)
where match
group by attribute_name, value
order by attribute_name, value
;
*/

-- lab min/max
drop table if exists _p_a_t_lab;
create table _p_a_t_lab as
select attribute_id, trial_id, person_id
, value_float as patient_value
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
where attribute_id in (409, 384, 386, 387)
    and nvl(inclusion, exclusion) ~ '^[0-9]+([.][0-9]+)?$'
group by attribute_id, person_id, trial_id, value_float, inclusion, exclusion
;
/*-- check
select attribute_name, value, clusion
, count(distinct person_id) patients, count(distinct trial_id) trials
from _p_a_t_lab join crit_attribute_used using (attribute_id)
where match
group by attribute_name, value, clusion
order by attribute_name, value, clusion::int
;
*/

/***
 * match diseases: matching using icd codes
 * requires: latest_icd
 * to be improved with the icd mapping
 */
drop table if exists _p_a_disease;
create table _p_a_disease as
select person_id, NULL as patient_value
, attribute_id
, case attribute_id
    when 201 then --Other malignancy: to exclude secondary C7[7-9B]
        bool_or(icd_code ~ '^(C[0-689]|C7[0-6A]|1[4-8]|19[0-59]|20)'
            and icd_code !~ '${cancer_type_icd}')
    -- when 199 then --autoimmune not implemented NULL
    when 194 then --brain met
        bool_or(icd_code ~ '^(C79\\.31|198\\.3)')
    when 195 then --brain met active ignored: to be improved later
        bool_or(icd_code ~ '^(C79\\.31|198\\.3)')
    when 196 then --Leptomeningeal
        bool_or(icd_code ~ '^(G93|348)')
    when 197 then --Carcinomatous meningitis
        bool_or(icd_code ~ '^(C70\\.9|192\\.1)')
    when 198 then --Spinal cord compression
        bool_or(icd_code ~ '^(G95\\.20|336\\.9)')
    when 200 then --Immunodeficiency/HIV infection
        bool_or(icd_code ~ '^(D84\\.9|279\\.3)')
    when 202 then --Cardiovascular disease
        bool_or(icd_code ~ '^(I50)')
    when 203 then --Interstitial lung disease
        bool_or(icd_code ~ '^(J84)')
    when 204 then --organ/bm tranplant
        bool_or(icd_code ~ '^(Z94)')
    when 255 then --HBV, HCV: icd9 to be added
        bool_or(icd_code ~ '^(B18\\.[0-2]|B16|B17\\.1)')
    when 421 then --non infectious pseumonitis
        bool_or(icd_code ~ '^(J84[.]89)')
    when 313 then --diabetic ketoacidosis
        bool_or(icd_code ~ '^(E10[.]1|250[.]11)')
    when 404 then --Seizure/predispose to seizure
        bool_or(icd_code ~'^(G4[05])')
    when 385 then --increased PSA
        bool_or(icd_code ~'^(R97[.]20|790[.]93)')
    when 410 then --liver or visceral mets
        bool_or(icd_code ~'^(C78[.]7|97[.]7)')
    when 411 then --bone mets
        bool_or(icd_code ~'^(79[.]51|98[.]5)')
    end as match
from crit_attribute_used
--join ref_disease_mapping using (attribute_name)
cross join latest_icd
where lower(attribute_group) ~ 'disease|condition'
    or attribute_id in (401)
group by attribute_id, person_id
order by person_id, attribute_id
;
/*qc
select attribute_name, value, count(*)
from _p_a_disease join crit_attribute_used using (attribute_id)
where match
group by attribute_name, value
order by attribute_name, value
;
-- more than 50% of patiets have cancer icds other thab LCA.
select regexp_substr(icd_code, '^...') icd, count(distinct person_id) patients
from latest_icd
where icd_code ~ '^(C[0-689]|C7[0-6A]|1[4-8]|19[0-59]|20)' and icd_code!~'${cancer_type_icd}'
group by icd
order by patients desc;
*/

/*** more diseases
where attribute_id=233 --value='IV (cirrhosis)'
, bool_or(icd_code ~ '^(K74\\.6|571\\.5)') as match
	when 'cardiovascular disease; yes' then 
		bool_or(icd_code ~ '^(I50)') -- icd9 to be added
	when 'autoimmune hepatitis; yes' then -- new
		bool_or(icd_code ~ '^(K75\\.4|571\\.42)') -- icd9 to be added
	when 'diabetic ketoacidosis; yes' then --new
		bool_or(icd_code ~ '^(E10\\.1)')
	when 'diabetes; yes' then 
		bool_or(icd_code ~ '^(E1[01])')
	when 'diabetes; diabetic ketoacidosis' then --old
		bool_or(icd_code ~ '^(E10\\.1)')
	when 'diabetes; t1d' then 
		bool_or(icd_code ~ '^(E10)')
	when 'diabetes; t2d' then 
		bool_or(icd_code ~ '^(E11)')
	When 'pancreatitis;	yes' then 
		bool_or(icd_code ~'^(K85)')
	when 'hypogonadism; yes' then 
		bool_or(icd_code ~ '^(E29\\.1|257\\.2)')
	-- liver
	when 'liver disease; alcoholic_steatohepatitis' then 
		bool_or(icd_code ~ '^(K70\\.1|571\\.1)')
	when 'liver disease; hcc' then 
		bool_or(icd_code ~ '^(C22|155)')
	when 'liver disease; alpha-1-antitrypsin deficiency' then 
		bool_or(icd_code ~ '^(E88\\.01|273\\.4)')
	when 'liver disease; (autoimmune) hepatitis' then --old
		bool_or(icd_code ~ '^(K75\\.4|571\\.42)')
	when 'liver disease; biliary cholangitis' then 
		bool_or(icd_code ~ '^(K74\\.3|571\\.6)')
	when 'liver disease; wilson' then 
		bool_or(icd_code ~ '^(E83\\.01|275\\.1)')
	when 'liver disease; Others (portal hypertension)' then 
		bool_or(icd_code ~ '^(K76\\.6|572\\.3)')
*/

/***
 * match line_of_therapy
 * requires: lot
 */
drop table _p_a_lot;
create table _p_a_lot as
select person_id, n_lot as patient_value
, attribute_id
, case when attribute_id between 147 and 150 then n_lot=value::int
    when attribute_id=151 then n_lot>=4  -- to be fixed in attribute excel
    end as match
from lot
cross join crit_attribute_used
where attribute_id between 147 and 151
;
/*-- check
select attribute_name, value, count(*)
from _p_a_lot join crit_attribute_used ca using (attribute_id)
where match
group by attribute_name, value
order by attribute_name, value
;
*/

/***
 * match drug therapies
 * requires: latest_lot_drug, ref_drug_mapping
 */
drop table person_lot_drug_cats;
create table person_lot_drug_cats as
select person_id
, listagg(distinct drug_name, '| ') within group (order by drug_name)
    as lot_drugs
, bool_or(modality ilike 'chemotherapy') chemo
, bool_or(modality ilike '%immunotherapy%') immuno
, bool_or(modality ilike '%targeted%') targeted
, bool_or(moa ~ 'platinum_based_chemo') platin
, bool_or(moa ~ 'PD_1_Ab') pd_1_ab
, bool_or(moa ~ 'PD_L1_Ab') pd_l1_ab
, bool_or(moa ~ 'CTLA_4_Ab') ctla_4_ab
, bool_or(moa ~ 'EGFR_targeted') egfr_targeted
, bool_or(moa ~ 'ALK_targeted') alk_targeted
, bool_or(moa ~ 'ROS1_(targeted|inhibitor)') ros1_targeted
, bool_or(moa ~ 'MEK_targeted') mek_targeted
, bool_or(moa ~ 'MET_targeted') met_targeted
, bool_or(moa ~ 'RET_targeted') ret_targeted
, bool_or(moa ~ 'VEGF_targeted') vegf_targeted
, bool_or(moa ~ 'VEGFR_targeted') vegfr_targeted
, bool_or(moa ~ 'RAF_targeted') raf_targeted
, bool_or(moa ~ 'BRAF_targeted') braf_targeted
, bool_or(moa ~ 'PARP_targeted') parp_targeted
, bool_or(moa ~ 'Taxanes') taxanes
, bool_or(moa ~ 'IL_2') il_2
, bool_or(moa ~ 'LHRH_(ant)?agonists') adt
, bool_or(moa ~ 'Anti_androgen') anti_androgen
, bool_or(moa ~ 'First_gen_anti_androgen') First_gen_anti_androgen
, bool_or(moa ~ 'Second_gen_anti_androgen') Second_gen_anti_androgen
from latest_lot_drug h
join ref_drug_mapping m using (drug_name)
group by person_id
;

drop table _p_a_hormone_therapy cascade;
create table _p_a_hormone_therapy as
select person_id, '' as patient_value
, attribute_id
, case attribute_id
    when 393 then adt
    when 395 then adt -- prior
    when 396 then adt -- progressed on
    when 397 then Second_gen_anti_androgen
    when 422 then First_gen_anti_androgen
    when 423 then lot_drugs ilike '%bicalutamide%'
    when 424 then lot_drugs ilike '%nilutamide%'
    when 425 then lot_drugs ilike '%flutamide%'
    when 398 then lot_drugs ilike '%abiraterone%'
    when 399 then lot_drugs ilike '%enzalutamide%'
    when 400 then lower(lot_drugs) ~ 'saviteronel|darolutamide|apalutamide'
    --when 408 then lower(lot_drugs) ~ 'testosterone' -- bipolar androgen therapy
    end as match
from person_lot_drug_cats
cross join crit_attribute_used
where lower(attribute_group)~'hormone.?therapy'
;
/*qc
select attribute_name, value, count(*)
from _p_a_hormone_therapy join crit_attribute_used using (attribute_id)
where match
group by attribute_name, value
order by attribute_name, value
;
*/
drop table if exists _p_a_chemotherapy cascade;
create table _p_a_chemotherapy as
select person_id, lot_drugs as patient_value
, attribute_id --, attribute_group, attribute_name, value
, case attribute_id --lower(nvl(attribute_name, '') || ', ' || value) 
    when 152 then chemo
    when 153 then platin
    when 154 then lot_drugs ilike '%cisplatin%'
    when 155 then lot_drugs ilike '%carboplatin%'
    when 156 then lot_drugs ilike '%docetaxel%'
    when 407 then taxanes
    when 403 then lot_drugs ilike '%cyclophosphamide%' or lot_drugs ilike '%mitoxantrone%'
    end as match
from person_lot_drug_cats
cross join crit_attribute_used
where lower(attribute_group)='chemotherapy'
;
/*qc
select attribute_name, value, count(*)
from _p_a_chemotherapy join crit_attribute_used using (attribute_id)
where match
group by attribute_name, value
order by attribute_name, value
;
*/

drop table _p_a_immunotherapy cascade;
create table _p_a_immunotherapy as
select person_id, lot_drugs as patient_value
, attribute_id
, case attribute_id
    when 157 then immuno
    when 158 then pd_1_ab
    when 159 then patient_value ilike '%pembrolizumab%'
    when 160 then patient_value ilike '%nivolumab%'
    when 161 then pd_l1_ab
    when 162 then patient_value ilike '%atezolizumab%'
    when 163 then patient_value ilike '%avelumab%'
    when 164 then patient_value ilike '%durmalumab%'
    when 165 then ctla_4_ab
    when 166 then patient_value ilike '%ipilimumab%'
    when 167 then il_2 --il related
    --when 168 then null --ox-40, cd137: not implemented yet
    end as match
from person_lot_drug_cats
cross join crit_attribute_used
where lower(attribute_group) ~ 'immun?otherapy' -- typo
;
/*qc
select attribute_name, value, count(*)
from _p_a_immunotherapy join crit_attribute_used using (attribute_id)
where match
group by attribute_name, value
order by attribute_name, value
;
select * from person_lot_drug_cats where immuno and not pd_1_ab; --sipuleucel-t
*/
drop table if exists _p_a_targetedtherapy;
create table _p_a_targetedtherapy as
select person_id, '' as patient_value
, attribute_id
, case attribute_id
    when 170 then targeted
    when 171 then egfr_targeted
    when 172 then patient_value ilike '%afatinib%'
    when 173 then patient_value ilike '%gefitinib%'
    when 174 then patient_value ilike '%erlotinib%'
    when 175 then patient_value ilike '%osimertinib%'
    when 176 then patient_value ilike '%cetuximab%'
    when 177 then alk_targeted
    when 178 then patient_value ilike '%crizotinib%'
    when 179 then patient_value ilike '%alectinib%'
    when 180 then patient_value ilike '%ceritinib%'
    when 181 then met_targeted --c-met
    when 182 then ret_targeted
    when 183 then patient_value ilike '%carbozantinib%'
    when 184 then parp_targeted
    when 185 then patient_value ilike '%olaparib%'
    when 186 then vegf_targeted or vegfr_targeted
    when 187 then ros1_targeted
    when 188 then braf_targeted
    when 189 then patient_value ilike '%vemurafenib%'
    when 190 then raf_targeted
    when 191 then patient_value ilike '%sorafenib%'
    when 192 then mek_targeted
    when 193 then patient_value ilike '%cobimetinib%'
    end as match
from person_lot_drug_cats
cross join crit_attribute_used
where lower(attribute_group)='targeted therapy'
;
/*qc
select attribute_name, value, count(*)
from _p_a_targetedtherapy join crit_attribute_used using (attribute_id)
where match
group by attribute_name, value
order by attribute_name, value
;
select distinct drugname from _line_of_therapy; --none
*/


/***
 * master sheet: need modifying for each cancer type!!
 */
drop table _p_a_t_match;
create table _p_a_t_match as
select attribute_id, trial_id, person_id, patient_value::varchar, match from _p_a_t_age
union select attribute_id, trial_id, person_id, patient_value::varchar, match from _p_a_t_weight
union select attribute_id, trial_id, person_id, patient_value::varchar, match from _p_a_t_lab
union select attribute_id, trial_id, person_id, patient_value::varchar, match from _p_a_t_blood_pressure
;

drop table _p_a_match;
create table _p_a_match as
--select attribute_id, person_id, patient_value::varchar, match from _p_a_age
--select attribute_id, person_id, patient_value::varchar, match from _p_a_histology
select attribute_id, person_id, patient_value::varchar, match from _p_a_stage
union select attribute_id, person_id, patient_value::varchar, match from _p_a_lab
union select attribute_id, person_id, patient_value::varchar, match from _p_a_lot
union select attribute_id, person_id, patient_value::varchar, match from _p_a_chemotherapy
union select attribute_id, person_id, patient_value::varchar, match from _p_a_hormone_therapy
union select attribute_id, person_id, patient_value::varchar, match from _p_a_immunotherapy
union select attribute_id, person_id, patient_value::varchar, match from _p_a_targetedtherapy
union select attribute_id, person_id, patient_value::varchar, match from _p_a_disease
union select attribute_id, person_id, patient_value::varchar, match from _p_a_ecog
union select attribute_id, person_id, patient_value::varchar, match from _p_a_karnofsky
union select attribute_id, person_id, patient_value::varchar, match from _p_a_mutation
;

drop view if exists _master_match;
create view _master_match as
select attribute_id, trial_id, person_id, patient_value::varchar, match
from _p_a_t_match
union
select attribute_id, trial_id, person_id, patient_value::varchar, match
from _p_a_match join trial_attribute_used using (attribute_id)
;

