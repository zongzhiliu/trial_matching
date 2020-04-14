/***
 * match diseases: matching using icd codes
 * requires: latest_icd
 * to be improved with the icd mapping
 */
-- alter table _p_a_disease rename to _p_a_disease_old;
drop table if exists _p_a_disease;
create table _p_a_disease as
select person_id, NULL as patient_value
, attribute_id
, bool_or (case attribute_id
    when 201 then --Other malignancy: to exclude secondary C7[7-9B]
        icd_code ~ '^(C[0-6]|C7[0-6]|C8[1-9]|C9[1-6])'
        --'^(C[0-689]|C7[0-6A]|C80|1[4-8]|19[0-59]|20)'
        and icd_code !~ '${cancer_type_icd}'
        and datediff(day, dx_date, '${protocal_date}')/365.25 <= 2
    -- when 199 then --autoimmune not implemented NULL
    when 194 then --brain met -- always requite a tempo
        icd_code ~ '^(C79[.]31|198[.]3)'
            and datediff(day, dx_date, '${protocal_date}')/365.25 <= 1
    when 195 then --brain met active ignored: to be improved later
        icd_code ~ '^(C79[.]31|198[.]3)'
            and datediff(day, dx_date, '${protocal_date}')/365.25 <= 1
    when 196 then --Leptomeningeal
        icd_code ~ '^(G93|348)'
    when 197 then --Carcinomatous meningitis
        icd_code ~ '^(C70[.]9|192[.]1)'
    when 198 then --Spinal cord compression
        icd_code ~ '^(G95[.]20|336[.]9)'
    when 200 then --Immunodeficiency/HIV infection
        icd_code ~ '^(D84[.]9|279[.]3)'
    when 202 then --Cardiovascular disease
        icd_code ~ '^(I50)'
    when 203 then --Interstitial lung disease
        icd_code ~ '^(J84)'
    when 204 then --organ/bm tranplant
        icd_code ~ '^(Z94)'
    when 255 then --HBV, HCV: icd9 to be added
        icd_code ~ '^(B18[.][0-2]|B16|B17[.]1)'
    when 421 then --non infectious pseumonitis
        icd_code ~ '^(J84[.]89)'
    when 313 then --diabetic ketoacidosis
        icd_code ~ '^(E10[.]1|250[.]11)'
    when 404 then --Seizure/predispose to seizure
        icd_code ~'^(G4[05])'
    when 385 then --increased PSA
        icd_code ~'^(R97[.]20|790[.]93)'
    when 410 then --liver or visceral mets
        icd_code ~'^(C78[.]7|97[.]7)'
    when 411 then --bone mets
        icd_code ~'^(C79[.]5|98[.]5)'
    end) as match
from (crit_attribute_used cross join latest_icd)
where attribute_id in (201, 194, 195, 196, 197, 198, 200, 202, 203, 204, 255, 421, 313, 404, 385, 410, 411)
group by attribute_id, person_id
;
/*qc: other maligancy, ILD, CHF has double numbers if not by person_id??
select attribute_name, attribute_value, count(distinct person_id)
from _p_a_disease join crit_attribute_used using (attribute_id)
where match
group by attribute_name, attribute_value
order by attribute_name, attribute_value
;
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

