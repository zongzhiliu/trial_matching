/***
Requires: cohort, dmsdw
Results: _sochx, sochx_alcohol
 */
-- socialHx (Tobacco, alcohol, sexual, illicit drug, ...)
-- weekly_low >= 24 is defined as abuse, e.g.  beer or wine we don't know yet
create table _sochx as
select distinct mrn
, age_in_days_key::int as age_in_days
, level3_action_name, level4_field_name
, value, unit_of_measure
from (cohort
join ${dmsdw}.d_person on medical_record_number=mrn)
join ${dmsdw}.fact f using (person_key)
join ${dmsdw}.d_metadata m using (meta_data_key)
join ${dmsdw}.D_UNIT_OF_MEASURE using (uom_key)
where level2_event_name='Social History' 
;

create table sochx_alcohol as
select mrn, age_in_days
, value::float as weekly_high, unit_of_measure
from (
    select *, row_number() over (
            partition by mrn
            order by value::float desc nulls last, unit_of_measure, age_in_days)
        from _sochx
        where level3_action_name='Alcohol'
            and level4_field_name='Weekly High'
)
where row_number=1
;

