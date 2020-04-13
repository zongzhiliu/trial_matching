/***
Requires:
    trial_attribute_used
    crit_attribute_used
    ref_drug_mapping
    ref_lab_mapping

    demo, stage
    latest_ecog, latest_karnofsky
    gene_alterations_pivot
Results:
    pa_stage, ecog, karnofsky, lot
*/
/***
 * match stage, status: multiple sele
 */
drop table if exists _p_a_stage;
create table _p_a_stage as
select person_id, attribute_id
, bool_or (case attribute_value
     when '0' then stage_base='0'
     when 'I' then stage_base='I'
     when 'IA' then stage like 'IA%'
     when 'IB' then stage like 'IB%'
     when 'II' then stage_base='II'
     when 'IIA' then stage like 'IIA%'
     when 'IIB' then stage like 'IIB%'
     when 'IIC' then stage like 'IIC%'
     when 'III' then stage_base='III'
     when 'IIIA' then stage like 'IIIA%'
     when 'IIIB' then stage like 'IIIB%'
     when 'IIIC' then stage like 'IIIC%'
     when 'IV' then stage_base='IV'
     when 'IVA' then stage like 'IVA%'
     when 'IVB' then stage like 'IVB%'
     when 'limited stage' then stage_base between 'I' and 'III'
     when 'extensive stage' then stage_base = 'IV'
     end) as match
, listagg(stage, '| ') as patient_value
from stage
join crit_attribute_used on attribute_name='stage'
group by person_id, attribute_id
;
/*-- check
select attribute_name, attribute_value, count(*)
from _p_a_stage join crit_attribute_used using (attribute_id)
where match
group by attribute_name, attribute_value
order by attribute_name, attribute_value
;
*/

/***
* match performance
*/
-- ecog from latest_ecog
drop table if exists _p_a_ecog;
create table _p_a_ecog as
select person_id, ecog_ps as patient_value
, attribute_id
, patient_value=attribute_value::int as match
from latest_ecog
cross join crit_attribute_used
where lower(attribute_name)='ecog'
;
--select * from _p_a_ecog;
/*-- check
select attribute_name, attribute_value, count(*)
--select patient_value
from _p_a_ecog join ct.crit_attribute using (attribute_id)
where match
group by attribute_name, attribute_value
;
*/

-- karnofsky
drop table if exists _p_a_karnofsky;
create table _p_a_karnofsky as
select person_id, karnofsky_pct as patient_value
, attribute_id
, patient_value=attribute_value::int as match
from latest_karnofsky
cross join crit_attribute_used
where lower(attribute_name)='karnofsky'
;

/*-- check
select attribute_name, attribute_value, count(*)
from _p_a_karnofsky join crit_attribute_used using (attribute_id)
where match
group by attribute_name, attribute_value
;
*/

/***
 * match line_of_therapy
 * requires: lot
 */
drop table _p_a_lot;
create table _p_a_lot as
select person_id, n_lot as patient_value
, attribute_id
, case
    when attribute_id between 147 and 150 then n_lot=attribute_value::int
    when attribute_id=151 then n_lot>=4
    end as match
from lot
cross join crit_attribute_used
where attribute_id between 147 and 151
;
/*-- check
select attribute_name, attribute_value, count(*)
from _p_a_lot join crit_attribute_used ca using (attribute_id)
where match
group by attribute_name, attribute_value
order by attribute_name, attribute_value
;
*/

