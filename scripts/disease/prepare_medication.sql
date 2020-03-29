
create table _rx as
select distinct mrn, age_in_days_key::int as age_in_days
, level1_context_name as source
, level2_event_name as rx_event
, level3_action_name as rx_action
, level4_field_name as rx_detail
, value
, material_name as rx_name
, generic_name as rx_generic
, material_type
, context_material_code
, context_name
from _person
join ${dmsdw}.fact using (person_key)
join ${dmsdw}.d_metadata using (meta_data_key)
join ${dmsdw}.b_material using (material_group_key)
join ${dmsdw}.fd_material using (material_key)
where meta_data_key in (3810,3811,3814,4781,4788,4826,5100,5115,5130,5145,
    2573,2574,4819,4814,4809,4804,5656,5655,5653,5649,2039,2040,2041,2042,
    5642,5643,5645,4802,4803,4805)
;
/*
where level2_event_name='Medication Administration'
        and (level3_action_name='Given' and level4_field_name !~ 'Comments|Entered By| ID| [dny] Date' -- not due date
            -- Dose, Administered (Note|Unit|Status), Bolus Drug, Infusion (Drug|Rate), (Medication )?Route( Detail)?, Site, Reason, Due Date, Repeat Patttern and Duration
            or level3_action_name in ('Acknowledged', 'Held', 'Ordered') and level4_field_name='Dose')
    or level2_event_name='Prescription'
        and (level4_field_name='SIG' and level3_action_name not in ('Suspend', 'Canceled')
            -- Written, Verified, Pending Verify, Dispensed, Completed, Discontinued, Others
            or level4_field_name='Dose' and level3_action_name='Written')
*/

/*
--select count(distinct mrn) from tmp
select * from _rx
where mrn in (select distinct mrn from tmp)
order by mrn, age_in_days, rx_event, rx_action, rx_name, rx_detail
;
select source, rx_event, rx_action, rx_detail, material_type
, count(*) records, count(distinct mrn) patients, count(distinct rx_name) meds, count(distinct rx_generic) drugs
from _rx
group by source, rx_event, rx_action, rx_detail, material_type
;
-- Administered_status not useful 'Given'
-- Due Date not useful
-- Administered Unit and Route better to pivot columns
-- COMPURECORD, SIGNOUT?? scott
-- TDS material type Not available??
-- Site??  scott
-- action - IBEX only: Held=6, ordered=27, Acknowledged_Dose=53, Given_Repeat Pattern=105
*/

drop table if exists rx;
create table rx AS
select mrn, age_in_days, rx_name, rx_generic
, listagg(distinct source, ' |') sources
, listagg(distinct rx_event, ' |') rx_events
, listagg(distinct rx_action, ' |') rx_actions
, listagg(distinct rx_detail, ' |') within group (order by rx_detail) rx_details
from _rx
group by mrn, age_in_days, rx_name, rx_generic
;
/*
select * from rx
order by mrn, age_in_days, rx_name, rx_generic
;
*/

drop table if exists latest_rx;
create table latest_rx as
select mrn person_id
, drug_name, moa, modality
, dateadd(day, age_in_days, date_of_birth)::date rx_date
from (select *, row_number() over (
        partition by mrn, drug_name
        order by -age_in_days)
    FROM rx
    JOIN _all_name an using(rx_name)
    JOIN ref_drug_mapping mp using (drug_name))
join demo using (mrn)
where row_number=1
;
/*
select count(*), count(distinct person_id) from lastest_rx;
select * from lastest_rx limit 99;
*/

create table _all_drugs as
select rx_name, nvl(rx_generic, '_') rx_generic
, count(*) records, count(distinct mrn) patients
from rx r 
group by rx_name, rx_generic
;

select * from _all_drugs;
select drug_name, rx_generic, rx_name, patients
from ct.drug_mapping_cat_expn5_20200317 dm 
left join _all_drugs ad on drug_name=lower(rx_generic) or lower(rx_name) like '%'||drug_name||'%'
where patients is not null 
	and drug_name != lower(rx_generic) --must be right
order by drug_name, nvl(rx_generic, '_'), rx_name
;

create table rx_list as
select rx_name, rx_generic
, count(*) rx_days, count(distinct mrn) patients
from rx
group by rx_name, rx_generic
order by patients desc, rx_days desc
;
*/

