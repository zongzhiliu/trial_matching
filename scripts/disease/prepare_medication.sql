
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

create table rx_list as
select rx_name, rx_generic
, count(*) rx_days, count(distinct mrn) patients
from rx
group by rx_name, rx_generic
order by patients desc, rx_days desc
;
*/

