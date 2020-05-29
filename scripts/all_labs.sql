/* copy here from dev_patient_info/sql/all_labs.sql
*/
set search_path=ct;

create view lab_loinc_mapping as
select * from resource.all_loinc_mappings_20191018
;
-- refresh lab_loinc_map table
create table lab_loinc_map as
select code as source_code,
    alias as source_test_name,
    unit as source_unit,
    loinc as loinc_code,
    default_unit,
    cast(factor as real) as factor,
    case when unit_flag = 'Y' then true else false end as unit_flag,
    case when lca = 'Y' then true else false end as lca,
    case when mm = 'Y' then true else false end as mm,
    case when pca = 'Y' then true else false end as pca
from lab_loinc_mapping; -- This table name will change depending on how David names it

-- 1. create loinc map table
create temporary table loinc as
select
    l.loinc_code,
    l.source_code,
    l.source_test_name,
    COALESCE(l.source_unit, 'NULL') as source_unit,
    l.default_unit,
    l.factor,
    c.loinc_display_name,
    c.loinc_long_name
from lab_loinc_map l
join resource.lab_test_loinc c
on c.loinc_code = l.loinc_code;


-- 2. get raw epic labs
create temporary table labs_epic as
with fish as
(
    select n.order_id,
        n.line,
        listagg(n.results_cmt, ' ') as test_result_value
    from ${dmsdw}.epic_lab l
    join ${dmsdw}.epic_lab_note n on l.order_proc_id = n.order_id and l.line = n.line
    where l.result_status in ('FINAL','CORRECTED')
        and		l.test_code in (15461, 15462)
        and n.line_comment between (
            select b.line_comment + 1
            from (
                select *, row_number() over (partition by order_id, line order by line_comment desc) as rn
                from ${dmsdw}.epic_lab_note
                where results_cmt = 'FISH RESULTS:'
                ) b
            where b.rn = 1
            and b.order_id = n.order_id
            and b.line = n.line
        ) and (
            select b.line_comment - 1
            from (
                select *, row_number() over (partition by order_id, line order by line_comment desc) as rn
                from ${dmsdw}.epic_lab_note
                where results_cmt = 'INTERPRETATION and COMMENTS:'
                ) b
            where b.rn = 1
            and b.order_id = n.order_id
            and b.line = n.line
        )
    group by n.order_id, n.line
)
select
    order_proc_id,
    line,
    mrn,
    age_in_days_key,
    test_code,
    test_name,
    lab_status,
    result_status,
    result_flag,
    abnormal_flag,
    reference_range,
    coalesce(unit_of_measurement, 'NULL') as unit_of_measurement,
    test_result_value
from ${dmsdw}.epic_lab
where result_status in ('FINAL','CORRECTED')
and test_code not in (15461, 15462)
union all
SELECT
    l.order_proc_id,
    l.line,
    l.mrn,
    l.age_in_days_key,
    l.test_code,
    l.test_name,
    l.lab_status,
    l.result_status,
    l.result_flag,
    l.abnormal_flag,
    l.reference_range,
    coalesce(l.unit_of_measurement, 'NULL') as unit_of_measurement,
    f.test_result_value
FROM ${dmsdw}.epic_lab l
join fish f
on l.order_proc_id = f.order_id
and l.line = f.line;

-- epic labs with formatted values
create temporary table epic_labs as
select
  mrn,
  age_in_days_key,
  cast(test_code as varchar(70)) as test_code,
  test_name,
  test_result_value,
  rtrim(ltrim(test_result_value, '''"*?!+:, '), '''"*?!+:., ') as test_result_value_clean,
  regexp_substr(rtrim(ltrim(test_result_value, '''"*?!+:, '), '''"*?!+:., '), '^\\s*[0-9]+(\\.[0-9]+)?\\s*$') as test_result_numeric,
  regexp_substr(rtrim(ltrim(test_result_value, '''"*?!+:, '), '''"*?!+:., '), '^\\s*[0-9]+(\\.[0-9]+)?\\s*\\-\\s*[0-9]+(\\.[0-9]+)?\\s*$') as source_range_result,
  split_part(regexp_substr(rtrim(ltrim(test_result_value, '''"*?!+:, '), '''"*?!+:., '), '^\\s*[0-9]+(\\.[0-9]+)?\\s*\\-\\s*[0-9]+(\\.[0-9]+)?\\s*$'), '-', 1) as source_range_value_low,
  split_part(regexp_substr(rtrim(ltrim(test_result_value, '''"*?!+:, '), '''"*?!+:., '), '^\\s*[0-9]+(\\.[0-9]+)?\\s*\\-\\s*[0-9]+(\\.[0-9]+)?\\s*$'), '-', 2) as source_range_value_high,
  regexp_substr(rtrim(ltrim(test_result_value, '''"*?!+:, '), '''"*?!+:., '), '^\\s*(<|<=|>|>=)\\s*[0-9]+(\\.[0-9]+)?\\s*$') as source_op_result,
  case when regexp_substr(test_result_value, '^\\s*(<|<=|>|>=)\\s*[0-9]+(\\.[0-9]+)?\\s*$') ~ '<' then '<'
      when regexp_substr(test_result_value, '^\\s*(<|<=|>|>=)\\s*[0-9]+(\\.[0-9]+)?\\s*$') ~ '<=' then '<='
      when regexp_substr(test_result_value, '^\\s*(<|<=|>|>=)\\s*[0-9]+(\\.[0-9]+)?\\s*$') ~ '>' then '>'
      when regexp_substr(test_result_value, '^\\s*(<|<=|>|>=)\\s*[0-9]+(\\.[0-9]+)?\\s*$') ~ '>=' then '>='
  end as source_op_result_operator,
  ltrim(regexp_substr(rtrim(ltrim(test_result_value, '''"*?!+:, '), '''"*?!+:., '), '^\\s*(<|<=|>|>=)\\s*[0-9]+(\\.[0-9]+)?\\s*$'), '<>= ') as source_op_result_value,
  coalesce(unit_of_measurement, 'NULL') as unit_of_measure
from  labs_epic;
drop table labs_epic;

-- 3. msdw raw lab dat
create temporary table labs_msdw as
select distinct
    p.medical_record_number as mrn,
    --c.calendar_date as result_date,
    l.age_in_days_key,
    prc.context_procedure_code as source_code,
    prc.procedure_description as source_test_name,
    l.value as source_value,
    coalesce(u.unit_of_measure, 'NULL') as source_unit
--select level1_context_name, level2_event_name, level3_action_name, count(*)
from dmsdw_testing.cohort
join ${dmsdw}.d_person p using (medical_record_number )
join ${dmsdw}.fact_lab l using (person_key)
join ${dmsdw}.d_metadata m using (meta_data_key)
join ${dmsdw}.b_procedure b using (procedure_group_key)
join ${dmsdw}.fd_procedure prc using (procedure_key)
join ${dmsdw}.d_unit_of_measure u using (uom_key)
WHERE m.level1_context_name = 'SCC'
and M.LEVEL2_EVENT_NAME = 'Lab Test'
and m.level3_action_name in ('Corrected Result','Final Result')
and m.level4_field_name in (
    'Clinical Result Numeric',
    'Clinical Result String',
    'Clinical Result Text[01]')
and prc.procedure_type = 'Lab Test'
and prc.procedure_description not in ('CBC & PLT & DIFF','COMP. METABOLIC PANEL', 'REFERRING PHYSICIAN PHONE', 'SEQUENTL INTEGRATED SCR,2');
-- msdw labs with formatted values
create temporary table msdw_labs as
select
    mrn,
    age_in_days_key::varchar, --quickfix
    source_code,
    source_test_name,
    source_value,
    rtrim(ltrim(source_value, '''"*?!+:, '), '''"*?!+:., ') as source_value_clean,
    regexp_substr(rtrim(ltrim(source_value, '''"*?!+:, '), '''"*?!+:., '), '^\\s*[0-9]+(\\.[0-9]+)?\\s*$') as source_value_numeric,
    regexp_substr(rtrim(ltrim(source_value, '''"*?!+:, '), '''"*?!+:., '), '^\\s*[0-9]+(\\.[0-9]+)?\\s*\\-\\s*[0-9]+(\\.[0-9]+)?\\s*$') as source_range_result,
    split_part(regexp_substr(rtrim(ltrim(source_value, '''"*?!+:, '), '''"*?!+:., '), '^\\s*[0-9]+(\\.[0-9]+)?\\s*\\-\\s*[0-9]+(\\.[0-9]+)?\\s*$'), '-', 1) as source_range_value_low,
    split_part(regexp_substr(source_value, '^\\s*[0-9]+(\\.[0-9]+)?\\s*\\-\\s*[0-9]+(\\.[0-9]+)?\\s*$'), '-', 2) as source_range_value_high,
    regexp_substr(rtrim(ltrim(source_value, '''"*?!+:, '), '''"*?!+:., '), '^\\s*(<|<=|>|>=)\\s*[0-9]+(\\.[0-9]+)?\\s*$') as source_op_result,
    case when regexp_substr(source_value, '^\\s*(<|<=|>|>=)\\s*[0-9]+(\\.[0-9]+)?\\s*$') ~ '<' then '<'
        when regexp_substr(source_value, '^\\s*(<|<=|>|>=)\\s*[0-9]+(\\.[0-9]+)?\\s*$') ~ '<=' then '<='
        when regexp_substr(source_value, '^\\s*(<|<=|>|>=)\\s*[0-9]+(\\.[0-9]+)?\\s*$') ~ '>' then '>'
        when regexp_substr(source_value, '^\\s*(<|<=|>|>=)\\s*[0-9]+(\\.[0-9]+)?\\s*$') ~ '>=' then '>='
    end as source_op_result_operator,
    ltrim(regexp_substr(rtrim(ltrim(source_value, '''"*?!+:, '), '''"*?!+:., '), '^\\s*(<|<=|>|>=)\\s*[0-9]+(\\.[0-9]+)?\\s*$'), '<>= ') as source_op_result_value,
    source_unit
from  labs_msdw
;
-- drop labs_msdw work table
drop table labs_msdw;

-- 4. create work table with all labs
create temporary table _all_labs as
select * from msdw_labs
union
select * from epic_labs;
drop table msdw_labs;
drop table epic_labs;

-- insert final labs data into dev_patient_info_pan.all_labs
CREATE TABLE all_labs_test as
select distinct
    a.mrn,
    a.age_in_days_key,
    case
        when a.source_range_result is not null and len(a.source_range_result) > 0 and a.source_range_value_low is not null and len(a.source_range_value_low) > 0 and len(a.source_range_value_low) <= 34 and a.source_range_value_high is not null and len(a.source_range_value_high) > 0 and len(a.source_range_value_high) <= 34
            then cast(cast((cast(a.source_range_value_low as decimal(38,4)) * coalesce(l.factor, 1)) as decimal(38,4)) as varchar) || ' - ' || cast(cast((cast(a.source_range_value_high as decimal(38,4)) * coalesce(l.factor, 1)) as decimal(38,4)) as varchar)
        when a.source_op_result is not null and len(a.source_op_result) > 0 and len(a.source_op_result) <= 34
            then a.source_op_result_operator || cast(cast((cast(a.source_op_result_value as decimal(38,4)) * coalesce(l.factor, 1)) as decimal(38,4)) as varchar)
        when (a.source_value_numeric is null or len(a.source_value_numeric) = 0 or len(a.source_value_numeric) > 34) then a.source_value
    end as value_text,
    case
        when a.source_value_numeric is not null and len(a.source_value_numeric) > 0 and len(a.source_value_numeric) <= 34
            then cast((cast(a.source_value_numeric as decimal(38,4)) * coalesce(l.factor, 1)) as decimal(38,4))
        when a.source_range_value_high is not null and len(a.source_range_value_high) > 0
            then cast((cast(a.source_range_value_high as decimal(38,4)) * coalesce(l.factor, 1)) as decimal(38,4))
        when a.source_op_result_value is not null and len(a.source_op_result_value) > 0
            then cast((cast(a.source_op_result_value as decimal(38,4)) * coalesce(l.factor, 1)) as decimal(38,4))
    end as value_float,
    case when a.source_range_value_low is not null and len(a.source_range_value_low) > 0 then cast((cast(a.source_range_value_low as decimal(38,4)) * coalesce(l.factor, 1)) as decimal(38,4))
        when a.source_value_numeric is not null and len(a.source_value_numeric) > 0 and len(a.source_value_numeric) <= 34 then cast((cast(a.source_value_numeric as decimal(38,4)) * coalesce(l.factor, 1)) as decimal(38,4))
        when a.source_op_result_operator in ('>', '>=') then cast((cast(a.source_op_result_value as decimal(38,4)) * coalesce(l.factor, 1)) as decimal(38,4))
        when a.source_op_result_operator in ('<', '<=') then 0
    end as value_range_low,
    case
        when a.source_range_value_high is not null and len(a.source_range_value_high) > 0 then cast((cast(a.source_range_value_high as decimal(38,4)) * coalesce(l.factor, 1)) as decimal(38,4))
        when a.source_value_numeric is not null and len(a.source_value_numeric) > 0 and len(a.source_value_numeric) <= 34 then cast((cast(a.source_value_numeric as decimal(38,4)) * coalesce(l.factor, 1)) as decimal(38,4))
        when a.source_op_result_operator in ('>', '>=') then cast((cast(a.source_op_result_value as decimal(38,4)) * coalesce(l.factor, 1)) as decimal(38,4))
        when a.source_op_result_operator in ('<', '<=') then cast((cast(a.source_op_result_value as decimal(38,4)) * coalesce(l.factor, 1)) as decimal(38,4))
    end as value_range_high,
    l.loinc_code,
    l.loinc_long_name,
    l.loinc_display_name,
    l.default_unit as unit,
    a.source_test_name,
    a.source_value,
    a.source_value_clean,
    case
        when a.source_value_numeric is not null and len(a.source_value_numeric) > 0 and len(a.source_value_numeric) <= 34
            then cast(a.source_value_numeric as decimal(38,4))
        else null
    end as source_value_numeric,
    a.source_range_result,
    a.source_range_value_low,
    a.source_range_value_high,
    a.source_op_result,
    a.source_op_result_operator,
    a.source_op_result_value,
    upper(a.source_unit) as source_unit
from _all_labs a
left join loinc l using (source_code, source_test_name, source_unit)
left join resource.loinc_low_high_values hl using (loinc_code)
-- only keep valid result values
WHERE value_float IS NULL
    OR hl.loinc_code IS NULL
    OR (
        value_float IS NOT NULL AND
        hl.loinc_code IS NOT NULL AND
        value_float >= nvl(hl.low_value, value_float) AND
        value_float <= nvl(hl.high_value, value_float)
    );

drop table _all_labs;
drop table loinc;

-- sanity check
-- 260515532


