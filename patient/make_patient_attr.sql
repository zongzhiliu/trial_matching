/***
input: 
 ct.attribute: attribute library for all diseases
 .trial_attribute: each trial matched to attributes
 .attribute_crit: a subset of attributes used in any inc/exc of trials

*/
set search_path=ct_nsclc;
create table ct_nsclc.cohort as
	select distinct person_id
	, histologic_icdo, histologic_type_name as histology
	, overall_stage stage
	, regexp_substr(stage, '^(I|II|III|IV)') stage_base
	, regexp_substr(stage, '[A-C].*') stage_ext
	, date_of_birth::date as date_of_birth
	, gender_name gender
	from cplus_from_aplus.cancer_diagnoses cd
	join prod_references.histologic_types h using (histologic_type_id, cancer_type_id)
	join cplus_from_aplus.person_mrns using (person_id)
	join cplus_from_aplus.cancer_types using (cancer_type_id)
    join cplus_from_aplus.people using (person_id)
    join cplus_from_aplus.genders using (gender_id)
	where cancer_type_name='LCA' and histologic_icdo !~ '804[1-5]/3' --small cell
		and date_of_death is null
;

create table demo as
select distinct person_id, date_of_birth dob, gender
from ct_nsclc.cohort
;

--performance: to be simplified later
create temporary table _last_performance as 
select person_id, ecog_ps, karnofsky_pct
from demo
left join (select *, row_number() over (partition by person_id
	order by performance_score_date desc, ecog_ps)
	from cplus_from_aplus.performance_scores) using (person_id)
where row_number=1 or row_number is null
;

alter table _last_performance add column karnofsky_ps int;
update _last_performance
set karnofsky_ps=tmp.karnofsky_ps
from (select person_id, k.ecog_ps as karnofsky_ps
	from _last_performance
	join cohort_filters.karnofsky_to_ecog k using (karnofsky_pct)
) as tmp
where _last_performance.person_id=tmp.person_id;

alter table _last_performance add column last_performance int;
update _last_performance set last_performance=nvl(ecog_ps, karnofsky_ps)
where true;

create table last_performance as select * from _last_performance;
select * from last_performance;

-- lot
create table max_lot as
select person_id, mrn, nvl(max(lot), 0) max_lot
from dev_patient_clinical_lca.line_of_therapy
join cplus_from_aplus.person_mrns using (mrn)
join demo using (person_id)
group by person_id, mrn
;

-- final table
drop table patient_attr;
create table ct_nsclc.patient_attr as
select person_id, histology
, stage
, case stage_base when '' then NULL else stage_base end as stage_base
, case stage_ext when '' then NULL else stage_ext end as stage_ext
, case stage_ext when '' then NULL else stage_base+stage_ext end as stage_full
, '' as status --mock for now
, gender, (datediff(day, date_of_birth, current_date)/365.25)::int age
, last_performance ecog
, nvl(l.max_lot, 0) max_lot
from cohort
left join last_performance using (person_id)
left join max_lot l using (person_id)
;
