/***
Requires: crit_attribute_used (using attribute_id and _value)
    cohort, stage
Results:
    pa_stage
*/
/***
 * match stage, status: multiple sele
 */
drop table if exists _p_a_stage cascade;
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
join crit_attribute_used on attribute_id between 29 and 43
group by person_id, attribute_id
;
create view qc_match_stage as
select attribute_name, attribute_value, count(*)
from _p_a_stage join crit_attribute_used using (attribute_id)
where match
group by attribute_name, attribute_value
order by attribute_name, attribute_value
;
