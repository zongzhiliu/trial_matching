
/***
 * histology
 * requires: $cancer_type
 */
set search_path=ct_${cancer_type};

drop table if exists histology;
create table histology as
select distinct person_id, histologic_type_id, histologic_type_name
from demo
join cplus_from_aplus.cancer_diagnoses cd using (person_id)
join prod_references.cancer_types using (cancer_type_id)
join prod_references.histologic_types ht using (histologic_type_id, cancer_type_id)
where nvl(cd.status, '')!='deleted'
    and cancer_type_name='${cancer_type}'
;
/*qc
select histologic_type_name, count(distinct person_id)
from histology join ct.pca_histology_category using (histologic_type_name)
group by histologic_type_name
order by histologic_type_name
;
*/
