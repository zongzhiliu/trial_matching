
drop table if exists _crit_attribute_logic;
create table _crit_attribute_logic as
with tmp as (
    select attribute_id, logic
    , split_part(logic, '/', 1) p1
    , split_part(logic, '/', 2) p2
    from crit_attribute_used
)
select attribute_id, logic
, case when nvl(p1, '')='' then attribute_id::varchar else p1 end logic_l1
, case when nvl(p2, '')='' then attribute_id::varchar else p2 end logic_l2
from tmp
order by logic
;

-- put logic into the trial_attribute table
