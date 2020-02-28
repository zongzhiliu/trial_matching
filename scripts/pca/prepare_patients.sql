/***
Dependencies
    demo (from cancer/prepare_patients.sql)
    cplus_from_aplus
Results:
    gleason
settings:
    @set cancer_type=PCA
    @set cancer_type_icd=^(C61|185)
*/
set search_path=ct_${cancer_type};
show search_path;

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

