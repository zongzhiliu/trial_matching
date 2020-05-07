drop table if exists _gender;
drop table if exists _dx_bca;
drop table if exists cat_measurement;

create table _gender as
select person_id, 'gender' as code
, case when gender_name in ('Male', 'Female') then gender_name
    end as value
from cohort
join cplus_from_aplus.people using (person_id)
join cplus_from_aplus.genders using (gender_id)
;

create table _dx_bca as
with tmp as(
    select person_id, er_status, pr_status, her2_status, menopausal_status
    from cohort
    join cplus_from_aplus.cancer_diagnoses using (person_id)
    join cplus_from_aplus.cancer_diagnoses_bca using(cancer_diagnosis_id)
)
select person_id, 'er_status' as code
, decode(er_status, 'Negative', 'Negative', 'Positive', 'Positive', NULL) value
from tmp union all
select person_id, 'pr_status' as code
, decode(pr_status, 'Negative', 'Negative', 'Positive', 'Positive', NULL)
from tmp union all
select person_id, 'her2_status' as code
, decode(her2_status, 'Negative', 'Negative', 'Positive', 'Positive', 'Equivocal', 'Equivocal', NULL)
from tmp union all
select person_id, 'menopausal_status' as code
, decode(menopausal_status, 'Premenopausal', 'Pre', 'Perimenopausal', 'Pre', 'Postmenopausal', 'Post', NULL)
from tmp union all
select person_id, 'tri_neg' as code
, case when er_status='Negative' and pr_status='Negative' and her2_status='Negative' then 'yes'
    else 'no' end
from tmp
;

create table cat_measurement as
select * from _gender union all
select * from _dx_bca
;
