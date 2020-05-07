/*
Results: trial_attribute_w_levels
Require: trial_attribute_updated
*/
drop table if exists trial_attribute_w_levels;
create table trial_attribute_w_levels as
with levels as (
    select trial_id, attribute_id
    , split_part(logic, '/', 1) p1
    , split_part(logic, '/', 2) p2
    , case when nvl(p1, '')='' then attribute_id::varchar else p1 end logic_l1
    , case when nvl(p2, '')='' then attribute_id::varchar else p2 end logic_l2
    from trial_attribute_updated
)
select ta.*
, logic_l1, logic_l2
from trial_attribute_updated ta
join levels using (trial_id, attribute_id)
;
/*
select * from trial_attribute_w_levels
order by trial_id, attribute_id
limit 99;
*/
