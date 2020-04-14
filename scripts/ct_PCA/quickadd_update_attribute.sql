/*
Results:
    crit_attribute_updated: pruned and updated with new group, name, value, mandatory/logic_default
    trial_attribute_updated: pruned and updated with new mandatory/logic
Require:
    master_match: for pruning
    _crit_attribute_raw_updated: for updating both crit and trial.
    crit/trial_attribute_used
*/

drop table if exists _crit_attribute_pruned;
create table _crit_attribute_pruned as
select * from crit_attribute_used
join (select distinct attribute_id from master_match) using (attribute_id);

drop table if exists _trial_attribute_pruned;
create table _trial_attribute_pruned as
select * from trial_attribute_used
join (select distinct attribute_id from master_match) using (attribute_id);

drop table if exists crit_attribute_updated cascade;
create table crit_attribute_updated as
select au.*
from _crit_attribute_raw_updated au
join _crit_attribute_pruned using(attribute_id)
;
/*
select * from crit_attribute_updated;
*/
drop table if exists trial_attribute_updated cascade;
create table trial_attribute_updated as
select ta.*
, case btrim(lower(mandatory_default))
    when 'yes' then True
    when 'no' then False
    when 'yes if exc' then not ie_flag
    end as mandatory
, case
    when logic_default ~ ' if inc$' then
        case when ie_flag then
            regexp_replace(logic_default, ' if inc$')
        else '' end
    else nvl(logic_default, '')
    end as logic
from _trial_attribute_pruned ta
join crit_attribute_updated using (attribute_id)
;
/*
select ta.*, mandatory_default, logic_default
from trial_attribute_updated ta
join crit_attribute_updated using (attribute_id)
limit 99;
*/

