/***
Requires:
    _master_match: from cancer/match_attributes.sql
    crit_attribute_used, trial_attribute_used, ref_histology_mapping
    histology, gleason: from pca/prepare_patients.sql
Results:
    _p_a_histology
    _p_a_t_gleason
    master_match
Settings:
    @set cancer_type=PCA
    @set cancer_type_icd=^(C61|185)
*/

set search_path=ct_${cancer_type};
-- show search_path;

/***
 * map histology
 * histology mapping file to be merged
 */
drop table if exists _p_a_histology cascade;
create table _p_a_histology as
select person_id, histologic_type_name as patient_value
, attribute_id
, case attribute_id
    --when 1 then nsclc
    --when 2 then nsclc and squamous
    --when 3 then nsclc and non_squamous
    --when 4 then sclc
    when 402 then non_small_cell_adenocarcinoma
    when 419 then small_cell_carcinoma
    when 420 then neuroendocrine_carcinoma
    end as match
from histology h
join ref_histology_mapping m using (histologic_type_name)
cross join crit_attribute_used
where lower(attribute_group)='histology'
;
/*-- check
select attribute_name, value, count(*)
from _p_a_histology join crit_attribute_used ca using (attribute_id)
where match
group by attribute_name, value
;
*/

/***
* patholgy
*/
drop table _p_a_t_gleason;
create table _p_a_t_gleason as
select attribute_id, trial_id, person_id
, '' as patient_value
, nvl(inclusion, exclusion)::int as clusion
, case attribute_id
    when 388 then gleason_score>=clusion --min
    when 389 then gleason_score<=clusion --max
    --when 390 then gleason primary
    --when 391 then gleason secondary
    end as match
from trial_attribute_used
join crit_attribute_used using (attribute_id)
cross join gleason
where attribute_name ilike 'gleason%'
;
/*-- check
select attribute_name, value, clusion
, count(distinct person_id) patients, count(distinct trial_id) trials
from _p_a_t_gleason join crit_attribute_used using (attribute_id)
where match
group by attribute_name, value, clusion
order by attribute_name, value, clusion::int
;
*/

/***
* finish the master_match
*/
drop table if exists master_match;
create table master_match as
select attribute_id, trial_id, person_id, patient_value::varchar, match
from _p_a_t_gleason
union
select attribute_id, trial_id, person_id, patient_value::varchar, match
from _p_a_histology join trial_attribute_used using (attribute_id)
union
select attribute_id, trial_id, person_id, patient_value::varchar, match
from _master_match
;
