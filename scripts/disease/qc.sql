
/* RX
*
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
