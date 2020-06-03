/*
Result: biomarker
Requires: cohort, cplus
*/
DROP TABLE IF EXISTS biomarker CASCADE;
CREATE TABLE biomarker AS
SELECT DISTINCT person_id, protein_biomarker_name, interpretation, positive_cell_pct
FROM cohort
join cplus_from_aplus.protein_biomarkers using (person_id)
;

create view qc_biomarker as
select protein_biomarker_name, count(distinct person_id)
from biomarker
group by protein_biomarker_name
;

select count(distinct person_id) from biomarker;
