set search_path=viecure_emr;

-- diagnosis
select count(*), count(distinct pt_id) from patient_diagnosis_current pdc;
	-- 143044	52843
select count(*), count(distinct pt_id) 
from patient_diagnosis_current pdc
join icd_code ic 
on lower(replace(pdc.diagnosis_code, '.', '')) = lower(btrim(ic.code_value));
	-- 70707	29305
select min(diagnosis_code) from patient_diagnosis_current; --008.45
select max(regexp_substr(diagnosis_code, '\\d+')::int) from patient_diagnosis_current; --82401

-- tests
select count(*), count(distinct pt_id) from patient_tests_current pdc;
	-- 961505	18495
select count(*), count(distinct pt_id) 
from patient_tests_current pdc
join loinc ic on lower(btrim(pdc.code)) = lower(btrim(ic.loinc_num));
--join uom on ;
	-- 919792	18455

-- medications
select count(*), count(distinct patient_id) from patient_medications_current pc;
	-- 315899	16759
select count(*), count(distinct patient_id)
from patient_medications_current pc
join drug_list d on btrim(pc.code)=btrim(d.fdb_id);
	-- 5744	3932
	
select count(*), count(distinct patient_id) from mar;
	-- 2382760	30590

-------
-- patient
select count(*)  from patient;
	-- 80913
select count(*) from patient p
join resource r on p.resource_id = r.id;
	--80892
select count(*), count(distinct pt_id) from patient_history_items; 
	--2238745	64644
select count(*), count(distinct patient_id) from patient_order; 
	--535	230 !!		
select count(*), count(distinct pt_id) from patient_notes; 
	-- 52227908	64579
	

-------------
-- cancer
select count(*), count(distinct patient_id) from patient_stage;
	-- 9803	6719
select count(*), count(distinct patient_id) from patient_stage ps
join stage_list sl on ps.stage_list_id = sl.id
join stage_type_list st on ps.stage_type_id =st.id
join patient_diagnosis_current pd on ps.diagnosis_id = pd.id;
	--good

select count(*), count(distinct patient_id) from patient_histology ph;
	-- 47	39
select count(*), count(distinct patient_id) from patient_histology ph 
join histology_list hl on ph.histology_list_id = hl.id;
	-- 0!

select count(*), count(distinct pt_id) from patient_gene_report_details p;
	-- 47	39
select count(*), count(distinct patient_id) from patient_histology ph 
join histology_list hl on ph.histology_list_id = hl.id;
