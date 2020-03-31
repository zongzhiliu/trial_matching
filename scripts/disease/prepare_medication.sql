/*
Requires: dmsdw, _person
Results: rx, latest_rx
*/

create temporary table _rx as
select distinct mrn, age_in_days_key::int as age_in_days
-- , level1_context_name as source
-- , level2_event_name as rx_event
-- , level3_action_name as rx_action
-- , level4_field_name as rx_detail
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
/* using the hard numbers to be consistent with Oracle alpha team.
*/

drop table if exists rx;
create table rx AS
select mrn, age_in_days, rx_name, rx_generic
-- , listagg(distinct source, ' |') sources
-- , listagg(distinct rx_event, ' |') rx_events
-- , listagg(distinct rx_action, ' |') rx_actions
-- , listagg(distinct rx_detail, ' |') within group (order by rx_detail) rx_details
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
    JOIN ref_rx_mapping an using(rx_name)
    JOIN ref_drug_mapping mp using (drug_name))
join demo using (mrn)
where row_number=1
;
/*
select count(*), count(distinct person_id) from lastest_rx;
select * from lastest_rx limit 99;
*/

/*
create table _all_drugs as
select rx_name, nvl(rx_generic, '_') rx_generic
, count(*) records, count(distinct mrn) patients
from rx r 
group by rx_name, rx_generic
;
*/

