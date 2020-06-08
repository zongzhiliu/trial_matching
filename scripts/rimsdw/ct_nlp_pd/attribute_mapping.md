```sql
set search_path=ct;
drop view qc_attribute_mapping_pd_mm_annotating;
create view qc_attribute_mapping_pd_mm_annotating as
with am as (
    select mm_attribute_id
    , attribute_id pd_attribute_id
    , attribute_group pd_group
    , attribute_name pd_name
    , attribute_value pd_value
    from attribute_mapping_pd_mm
    where mm_attribute_id is not null
)
select *
from am
join mm_v_crit_attribute_used_new on ct.py_contains(old_attribute_id, mm_attribute_id)
order by mm_attribute_id, new_attribute_id, pd_attribute_id
;
```
