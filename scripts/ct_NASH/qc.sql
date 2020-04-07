-- find the implemented attributes
with implemented as (
    select distinct attribute_id, attribute_group, attribute_name
    from v_master_sheet
    where attribute_match is not null
    order by attribute_id
)
-- find attributes with multiple ie_values (ie_value != attribute_value)
, ie_match as (
    select attribute_id, person_id, trial_id
    , lower(btrim(nvl(inclusion, exclusion))) as ie_value
    from v_master_sheet
    join implemented using (attribute_id)
)
select attribute_id
, 'implemented' as code_type, listagg(distinct ie_value, '| ') as ie_values
from ie_match
group by attribute_id
order by attribute_id
;
    -- only min/max needed to expand

-- a trial have same number of attributes accross patients
select trial_id, person_id
, count(*) attributes
from _master_sheet --_new
group by trial_id, person_id
order by trial_id, person_id
limit 99;

-- new and old master_sheet
select count(*), count(distinct attribute_id), count(distinct trial_id), count(distinct person_id) from v_master_sheet;

select count(*), count(distinct attribute_id)
, count(distinct trial_id)
, count(distinct person_id)
from _master_sheet_new;
select count(*), count(distinct new_attribute_id), count(distinct old_attribute_id)
, count(distinct trial_id), count(distinct person_id)
from master_sheet_new;

select count(*) from demo;
