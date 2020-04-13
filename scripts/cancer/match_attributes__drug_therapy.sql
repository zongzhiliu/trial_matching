/***
 * match drug therapies
 * requires: latest_lot_drug, ref_drug_mapping
 */
drop table person_lot_drug_cats;
create table person_lot_drug_cats as
select person_id
, listagg(distinct drug_name, '| ') within group (order by drug_name)
    as lot_drugs
, bool_or(modality ilike '%chemotherapy%') chemo
, bool_or(modality ilike '%immunotherapy%') immuno
, bool_or(modality ilike '%targeted%') targeted
, bool_or(moa ~ 'platinum_based_chemo') platin
, bool_or(moa ~ 'PD_1_Ab') pd_1_ab
, bool_or(moa ~ 'PD_L1_Ab') pd_l1_ab
, bool_or(moa ~ 'CTLA_4_Ab') ctla_4_ab
, bool_or(moa ~ 'EGFR_targeted') egfr_targeted
, bool_or(moa ~ 'ALK_targeted') alk_targeted
, bool_or(moa ~ 'ROS1_(targeted|inhibitor)') ros1_targeted
, bool_or(moa ~ 'MEK_targeted') mek_targeted
, bool_or(moa ~ 'MET_targeted') met_targeted
, bool_or(moa ~ 'RET_targeted') ret_targeted
, bool_or(moa ~ 'VEGF_targeted') vegf_targeted
, bool_or(moa ~ 'VEGFR_targeted') vegfr_targeted
, bool_or(moa ~ 'RAF_targeted') raf_targeted
, bool_or(moa ~ 'BRAF_targeted') braf_targeted
, bool_or(moa ~ 'PARP_targeted') parp_targeted
, bool_or(moa ~ 'Taxanes') taxanes
, bool_or(moa ~ '(^|\\W)IL[-_1-9][0-9]?($|\\D)') il_related
, bool_or(moa ~ 'LHRH_(ant)?agonists') adt
, bool_or(moa ~ 'Anti_androgen') anti_androgen
, bool_or(moa ~ 'First_gen_anti_androgen') First_gen_anti_androgen
, bool_or(moa ~ 'Second_gen_anti_androgen') Second_gen_anti_androgen
from latest_lot_drug h
join ref_drug_mapping m using (drug_name)
group by person_id
;

drop table _p_a_hormone_therapy cascade;
create table _p_a_hormone_therapy as
select person_id, '' as patient_value
, attribute_id
, case attribute_id
    when 393 then adt
    when 394 then adt -- ongoing
    when 395 then adt -- prior
    when 396 then adt -- progressed on
    when 397 then Second_gen_anti_androgen
    when 422 then First_gen_anti_androgen
    when 423 then lot_drugs ilike '%bicalutamide%'
    when 424 then lot_drugs ilike '%nilutamide%'
    when 425 then lot_drugs ilike '%flutamide%'
    when 398 then lot_drugs ilike '%abiraterone%'
    when 399 then lot_drugs ilike '%enzalutamide%'
    when 400 then lower(lot_drugs) ~ 'saviteronel|darolutamide|apalutamide'
    --when 408 then lower(lot_drugs) ~ 'testosterone' -- bipolar androgen therapy
    end as match
from person_lot_drug_cats
cross join crit_attribute_used
-- where lower(attribute_group)~'hormone.?therapy' -- bug for 394 if not implemented
where attribute_id in (393, 394, 395, 396, 397, 422, 423, 424, 425, 398, 399, 400)
;
/*qc
select attribute_name, attribute_value, count(distinct person_id)
from _p_a_hormone_therapy join crit_attribute_used using (attribute_id)
where match
group by attribute_name, attribute_value
order by attribute_name, attribute_value
;
*/
drop table if exists _p_a_chemotherapy cascade;
create table _p_a_chemotherapy as
select person_id, '' as patient_value
, attribute_id
, case attribute_id
    when 152 then chemo
    when 153 then platin
    when 154 then lot_drugs ilike '%cisplatin%'
    when 155 then lot_drugs ilike '%carboplatin%'
    when 156 then lot_drugs ilike '%docetaxel%'
    when 407 then taxanes
    when 403 then lot_drugs ilike '%cyclophosphamide%' or lot_drugs ilike '%mitoxantrone%'
    end as match
from person_lot_drug_cats
cross join crit_attribute_used
--where lower(attribute_group)='chemotherapy'
where attribute_id in ( 152, 153, 154, 155, 156, 407, 403)
;

/*qc
select attribute_name, attribute_value, count(distinct person_id)
from _p_a_chemotherapy join crit_attribute_used using (attribute_id)
where match
group by attribute_name, attribute_value
order by attribute_name, attribute_value
;
*/

drop table _p_a_immunotherapy cascade;
create table _p_a_immunotherapy as
select person_id, '' as patient_value
, attribute_id
, case attribute_id
    when 157 then immuno
    when 158 then pd_1_ab
    when 159 then lot_drugs ilike '%pembrolizumab%'
    when 160 then lot_drugs ilike '%nivolumab%'
    when 161 then pd_l1_ab
    when 162 then lot_drugs ilike '%atezolizumab%'
    when 163 then lot_drugs ilike '%avelumab%'
    when 164 then lot_drugs ilike '%durmalumab%'
    when 165 then ctla_4_ab
    when 166 then lot_drugs ilike '%ipilimumab%'
    when 167 then il_related --il related
    --when 168 then null --ox-40, cd137: not implemented yet
    end as match
from person_lot_drug_cats
cross join crit_attribute_used
--where lower(attribute_group) ~ 'immun?otherapy' -- typo
where attribute_id in (
    157, 158, 159, 160, 161, 162, 163, 164, 165, 166, 167
);

/*qc
select attribute_name, attribute_value, count(distinct person_id)
from _p_a_immunotherapy join crit_attribute_used using (attribute_id)
where match
group by attribute_name, attribute_value
order by attribute_name, attribute_value
;
select * from person_lot_drug_cats where immuno and not pd_1_ab; --sipuleucel-t
*/
drop table if exists _p_a_targetedtherapy;
create table _p_a_targetedtherapy as
select person_id, '' as patient_value
, attribute_id
, case attribute_id
    when 170 then targeted
    when 171 then egfr_targeted
    when 172 then lot_drugs ilike '%afatinib%'
    when 173 then lot_drugs ilike '%gefitinib%'
    when 174 then lot_drugs ilike '%erlotinib%'
    when 175 then lot_drugs ilike '%osimertinib%'
    when 176 then lot_drugs ilike '%cetuximab%'
    when 177 then alk_targeted
    when 178 then lot_drugs ilike '%crizotinib%'
    when 179 then lot_drugs ilike '%alectinib%'
    when 180 then lot_drugs ilike '%ceritinib%'
    when 181 then met_targeted --c-met
    when 182 then ret_targeted
    when 183 then lot_drugs ilike '%carbozantinib%'
    when 184 then parp_targeted
    when 185 then lot_drugs ilike '%olaparib%'
    when 186 then vegf_targeted or vegfr_targeted
    when 187 then ros1_targeted
    when 188 then braf_targeted
    when 189 then lot_drugs ilike '%vemurafenib%'
    when 190 then raf_targeted
    when 191 then lot_drugs ilike '%sorafenib%'
    when 192 then mek_targeted
    when 193 then lot_drugs ilike '%cobimetinib%'
    end as match
from person_lot_drug_cats
cross join crit_attribute_used
--where lower(attribute_group)='targeted therapy'
where attribute_id in (
    170, 171, 172, 173, 174, 175, 176, 177, 178, 179, 180, 181, 182, 183, 184, 185, 186, 187, 188
);
/*qc
189select attribute_name, attribute_value, count(distinct person_id)
190from _p_a_targetedtherapy join crit_attribute_used using (attribute_id)
191where match
192group by attribute_name, attribute_value
193order by attribute_name, attribute_value
;
select distinct drugname from _line_of_therapy; --none
*/


