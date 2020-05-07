/***
Dependencies
    demo (from cancer/prepare_patients.sql)
    cplus_from_aplus
Results:
    gleason
*/
create table gleason as
select person_id, gleason_grade, gleason_score, gleason_primary, gleason_secondary
from (select *, row_number() over (
        partition by person_id
        order by -gleason_score, -gleason_primary)
    from demo
    join cplus_from_aplus.cancer_diagnoses using (person_id)
    join cplus_from_aplus.cancer_diagnoses_pca using (cancer_diagnosis_id))
where row_number=1
;

