/***
dependencies
    prod_msdw.all_labs
    cplus_from_aplus
    prod_references
    dev_patient_info_${cancer_type}
    dev_patient_clinical_${cancer_type}
settings
    @set cancer_type=LCA
    @set current_schema=ct_${cancer_type}
*/
set search_path=ct_${cancer_type};
show search_path;

/***
 * biomarker: pd_l1

--select distinct protein_biomarker_name, assay, interpretation
select count(distinct person_id)
from cplus_from_aplus.protein_biomarkers
join cplus_from_aplus.pathologies using (pathology_id, person_id)
;
-- 616 persons in total
-- only 23 (3%) can be mapped to a pathology note?!

-- however all records have a patholgy_id
select pathology_id is null, count(*)
from cplus_from_aplus.protein_biomarkers
group by pathology_id is null
;

--create table ct_lca.p_latest_pd_l as
select person_id, interpretation
, positive_cell_pct, positive_cell_pct_source_value
, intensity_score
from (select *, row_number() over (
		partition by person_id
		order by tissue_collection_date desc nulls last, protein_biomarker_id)
	from cplus_from_aplus.protein_biomarkers b
	join cplus_from_aplus.pathologies p using (pathology_id, person_id)
	where p.status != 'deleted' and b.status != 'deleted')
where row_number=1
;
*/



