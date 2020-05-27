/* base on scott's script
C91.1 Chronic lymphocytic leukemia of B-cell type
•          C91.10 …… not having achieved remission (ICD9: 204.10)
•          C91.11 …… in remission (ICD9:204.11)
•          C91.12 …… in relapse (ICD9:204.12)

Trade names
Imbruvica, Ibrutix
Other names	Ibrutinib, PCI-32765, CRA-032765
*/

-- CLL with drugs
with cll as
         (
             SELECT DISTINCT P.MEDICAL_RECORD_NUMBER
             FROM dmsdw_2019q1.FACT F,
                  dmsdw_2019q1.D_METADATA M,
                  dmsdw_2019q1.D_PERSON P,
                  dmsdw_2019q1.B_DIAGNOSIS BD,
                  dmsdw_2019q1.FD_DIAGNOSIS D
             WHERE F.META_DATA_KEY = M.META_DATA_KEY
               AND (F.META_DATA_KEY = 3490 OR (F.META_DATA_KEY = 5719 AND F.ENCOUNTER_KEY > 3))
               AND F.PERSON_KEY = P.PERSON_KEY
               AND F.DIAGNOSIS_GROUP_KEY = BD.DIAGNOSIS_GROUP_KEY
               AND BD.DIAGNOSIS_KEY = D.DIAGNOSIS_KEY
               AND F.PERSON_KEY > 3
               AND F.DATA_STATE_KEY = 1
               AND D.context_name in ('ICD-10', 'ICD-9')
               and (D.context_name = 'ICD-10' and D.context_diagnosis_code in ('C91.1', 'C91.10', 'C91.12') or
                    D.context_name = 'ICD-9' and D.context_diagnosis_code in ('204.10', '204.12'))
         )
, drugs as
(
	select *
	from dmsdw_2019q1.d_material
	where material_type = 'Drug'
	and (	lower(generic_name) like '%imbruvica%'
		 or lower(generic_name) like '%ibrutix%'
		 or lower(generic_name) like '%ibrutinib%'
		 or	lower(generic_name) like '%pci-32765%'
		 or	lower(generic_name) like '%cra-032765%'
		 or lower(brand1) like '%imbruvica%'
		 or lower(brand1) like '%ibrutix%'
		 or lower(brand1) like '%ibrutinib%'
		 or lower(brand1) like '%pci-32765%'
		 or lower(brand1) like '%cra-032765%'
		 or lower(brand2) like '%imbruvica%'
		 or lower(brand2) like '%ibrutix%'
		 or lower(brand2) like '%ibrutinib%'
		 or lower(brand2) like '%pci-32765%'
		 or lower(brand2) like '%cra-032765%'
		 or lower(material_name) like '%imbruvica%'
		 or lower(material_name) like '%ibrutix%'
		 or lower(material_name) like '%ibrutinib%'
		 or	lower(material_name) like '%pci-32765%'
		 or	lower(material_name) like '%cra-032765%'
		)
)
select count(distinct p.medical_record_number)
  from dmsdw_2019q1.d_metadata 	m,
       dmsdw_2019q1.fact            		f,
       dmsdw_2019q1.d_person               p,
       dmsdw_2019q1.b_material             bm,
       drugs            				dm
 where m.level1_context_name = 'EPIC'
 and   m.level2_event_name in ('Prescription','Medication Administration', 'Medication Order', 'Medication Reported')
 and   m.meta_data_key = f.meta_data_key
 and   f.person_key = p.person_key
 and   f.material_group_key = bm.material_group_key
 and   bm.material_key = dm.material_key;


-- CLL patients
SELECT count(DISTINCT P.MEDICAL_RECORD_NUMBER)
FROM dmsdw_2019q1.FACT F,
  dmsdw_2019q1.D_METADATA M,
  dmsdw_2019q1.D_PERSON P,
  dmsdw_2019q1.B_DIAGNOSIS BD,
  dmsdw_2019q1.FD_DIAGNOSIS D
WHERE F.META_DATA_KEY = M.META_DATA_KEY
AND (F.META_DATA_KEY = 3490 OR (F.META_DATA_KEY = 5719 AND F.ENCOUNTER_KEY > 3))
AND F.PERSON_KEY = P.PERSON_KEY
AND F.DIAGNOSIS_GROUP_KEY = BD.DIAGNOSIS_GROUP_KEY
AND BD.DIAGNOSIS_KEY = D.DIAGNOSIS_KEY
AND F.PERSON_KEY > 3
AND F.DATA_STATE_KEY = 1
AND D.context_name in ('ICD-10', 'ICD-9')
and (D.context_name = 'ICD-10' and D.context_diagnosis_code in ('C91.1', 'C91.10', 'C91.12') or
    D.context_name = 'ICD-9' and D.context_diagnosis_code in ('204.10',  '204.12'))
-- 1588

-- CLL remission
SELECT count(DISTINCT P.MEDICAL_RECORD_NUMBER)
FROM dmsdw_2019q1.FACT F,
  dmsdw_2019q1.D_METADATA M,
  dmsdw_2019q1.D_PERSON P,
  dmsdw_2019q1.B_DIAGNOSIS BD,
  dmsdw_2019q1.FD_DIAGNOSIS D
WHERE F.META_DATA_KEY = M.META_DATA_KEY
AND (F.META_DATA_KEY = 3490 OR (F.META_DATA_KEY = 5719 AND F.ENCOUNTER_KEY > 3))
AND F.PERSON_KEY = P.PERSON_KEY
AND F.DIAGNOSIS_GROUP_KEY = BD.DIAGNOSIS_GROUP_KEY
AND BD.DIAGNOSIS_KEY = D.DIAGNOSIS_KEY
AND F.PERSON_KEY > 3
AND F.DATA_STATE_KEY = 1
AND D.context_name in ('ICD-10', 'ICD-9')
and (D.context_name = 'ICD-10' and D.context_diagnosis_code in ('C91.11') or
    D.context_name = 'ICD-9' and D.context_diagnosis_code in ('204.11'));
