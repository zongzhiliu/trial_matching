/* Result: cancer_dx
Required: cohort, cplus_from_aplus, prod_references
*/
drop table if exists cancer_dx cascade;
create table cancer_dx as
	select cancer_diagnosis_id, person_id
    , year_of_diagnosis dx_year, month_of_diagnosis dx_month, day_of_diagnosis dx_day
	, case when ajcc_clinical_t not in ('', 'Not Reported', 'Not Applicable', 'Nx')
        then ajcc_clinical_t end c_t
	, case when ajcc_clinical_n not in ('', 'Not Reported', 'Not Applicable', 'Nx')
	    then ajcc_clinical_n end as c_n
	, case when ajcc_clinical_m not in ('', 'Not Reported', 'Not Applicable', 'Mx')
	    then ajcc_clinical_m end as c_m
	, case when ajcc_pathological_t not in ('', 'Not Reported', 'Not Applicable', 'Tx')
	    then ajcc_pathological_t end as p_t
	, case when ajcc_pathological_n not in ('', 'Not Reported', 'Not Applicable', 'Nx')
	    then ajcc_pathological_n end as p_n
	, case when ajcc_pathological_m not in ('', 'Not Reported', 'Not Applicable', 'Mx')
	    then ajcc_pathological_m end as p_m
	, case when overall_stage not in ('', 'Not Reported', 'Not Applicable')
	    then overall_stage end stage_extracted
    , histologic_icdo, histologic_type_name
	from cohort
	join cplus_from_aplus.cancer_diagnoses using (person_id)
    join cplus_from_aplus.cancer_types using (cancer_type_id)
    join prod_references.histologic_types using (histologic_type_id, cancer_type_id)
    	where cancer_type_name='${cancer_type}'
;

select count(*) records, count(distinct person_id) patients from cancer_dx;
