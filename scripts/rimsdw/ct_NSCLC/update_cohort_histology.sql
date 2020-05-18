/* Filter the cohort using cancer_hisotolgy_cat
Requires: histology, cohort
Results: histology, cohort
*/
--select count(*) from histology;
delete from histology
using  ${ref_histology_mapping} r
where histology.histologic_type_name=r.histologic_type_name
    and not r.${cancer_histology_cat}
;
--select count(*) from histology;

--select count(*) from cohort;
delete from cohort
where cohort.person_id not in (select distinct person_id from histology)
;
--select count(*) from cohort;

