/** > latest_stage
Requires: stage_plus, cancer_dx
*/

drop table if exists latest_stage cascade;
create table latest_stage as
select person_id
, stage
, regexp_substr(stage, '^[0IV]+') stage_base
from (select *, row_number() over (
        partition by person_id
        order by -dx_year, -dx_month, -dx_day, stage desc nulls last)
    from stage_plus
    join cancer_dx using (cancer_diagnosis_id, person_id)
    where stage is not null
)
where row_number=1
;
create view stage as select * from latest_stage;
    -- quickfix for compatibility

select count(*) stage_records, count (distinct person_id) patients from stage_plus where stage is not null;
select count(*) stage_records, count (distinct person_id) patients from latest_stage;
-- select count(*) stage_records, count (distinct person_id) patients from stage_plus where stage is not null;
-- select count(*) stage_records, count (distinct person_id) patients from stage_plus where stage_extracted is not null;
