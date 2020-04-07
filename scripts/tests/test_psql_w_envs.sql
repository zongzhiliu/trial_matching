show search_path;
select '${cancer_type}';

with tmp as (
    select 'a' name, 'l1' logic_l1, 'l2' logic_l2 union all
    select 'b', 'l12', 'l22' union all
    select 'c', 'l13', 'l23'
)
select name, ${logic_cols}
from tmp
;
