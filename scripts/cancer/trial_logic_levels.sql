/*
Results: logic_levels
Require: trial_attribute_updated
*/
select distinct ct.assert(logic is not null, 'no NULL logic allowed, they can be empty text though')
from trial_attribute_updated;

drop table if exists trial_logic_levels cascade;
create table trial_logic_levels as
with parts as (
    select logic
    , split_part(logic, '/', 1) p1
    , split_part(logic, '/', 2) p2
    from (select distinct logic from trial_attribute_updated)
)
select trial_id, attribute_id
    , decode(p1, '', attribute_id::varchar, p1) logic_l1
    , decode(p2, '', attribute_id::varchar, p2) logic_l2
from trial_attribute_updated join parts using (logic)
;
/*
select * from trial_attribute_w_levels
order by trial_id, attribute_id
limit 99;
*/
