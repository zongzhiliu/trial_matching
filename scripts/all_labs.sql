/* copy here from dev_patient_info/sql/all_labs.sql
*/
-- refresh lab_loinc_map table
drop table if exists resource.lab_loinc_map_prev;
alter table resource.lab_loinc_map rename to lab_loinc_map_prev;
CREATE TABLE IF NOT EXISTS resource.lab_loinc_map
(
    source_code VARCHAR(70)   ENCODE zstd
    ,source_test_name VARCHAR(70)   ENCODE zstd
    ,source_unit VARCHAR(20)   ENCODE zstd
    ,loinc_code VARCHAR(10)   ENCODE zstd
    ,default_unit VARCHAR(20)   ENCODE zstd
    ,factor REAL   ENCODE RAW
    ,unit_flag BOOLEAN   ENCODE RAW
    ,lca BOOLEAN  DEFAULT false ENCODE RAW
    ,mm BOOLEAN  DEFAULT false ENCODE RAW
    ,pca BOOLEAN  DEFAULT false ENCODE RAW
)
DISTSTYLE AUTO
 SORTKEY (
    source_code
    , source_test_name
    , source_unit
    )
;

insert into resource.lab_loinc_map
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
from resource.lab_loinc_mapping; -- This table name will change depending on how David names it



-------------------------------------------------------------------------------------------------------------------
-- refresh prod_msdw.all_labs
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
from resource.lab_loinc_map l
join resource.lab_test_loinc c
on c.loinc_code = l.loinc_code;


-- 2. get raw epic labs
create temporary table labs_epic as
with fish as
(
    select
    n.order_id,
    n.line,
    listagg(n.results_cmt, ' ') as test_result_value
    from prod_msdw.epic_lab l
    join prod_msdw.epic_lab_note n
    on l.order_proc_id = n.order_id
    and l.line = n.line
    where l.result_status in ('FINAL','CORRECTED')
    and		l.test_code in (15461, 15462)
    and n.line_comment between
    (
        select b.line_comment + 1
        from (
            select *, row_number() over (partition by order_id, line order by line_comment desc) as rn
            from prod_msdw.epic_lab_note
            where results_cmt = 'FISH RESULTS:'
            ) b
        where b.rn = 1
        and b.order_id = n.order_id
        and b.line = n.line
    )
    and
    (
        select b.line_comment - 1
        from (
            select *, row_number() over (partition by order_id, line order by line_comment desc) as rn
            from prod_msdw.epic_lab_note
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
    birth_date,
    order_date,
    test_code,
    test_name,
    lab_status,
    result_status,
    result_flag,
    abnormal_flag,
    reference_range,
    coalesce(unit_of_measurement, 'NULL') as unit_of_measurement,
    test_result_value
from prod_msdw.epic_lab
where result_status in ('FINAL','CORRECTED')
and test_code not in (15461, 15462)
union all
SELECT
    l.order_proc_id,
    l.line,
    l.mrn,
    l.birth_date,
    l.order_date,
    l.test_code,
    l.test_name,
    l.lab_status,
    l.result_status,
    l.result_flag,
    l.abnormal_flag,
    l.reference_range,
    coalesce(l.unit_of_measurement, 'NULL') as unit_of_measurement,
    f.test_result_value
FROM prod_msdw.epic_lab l
join fish f
on l.order_proc_id = f.order_id
and l.line = f.line;

-- 3. epic labs with formatted values
create temporary table epic_labs as
select
  mrn,
  order_date,
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

-- 4. drop labs_epic work table
drop table labs_epic;

-- 5. msdw raw lab dat
create temporary table labs_msdw as
select distinct
    p.medical_record_number as mrn,
    c.calendar_date as result_date,
    prc.context_procedure_code as source_code,
    prc.procedure_description as source_test_name,
    l.value as source_value,
    coalesce(u.unit_of_measure, 'NULL') as source_unit
from prod_msdw.fact_lab l
join prod_msdw.d_metadata m
using (meta_data_key)
join prod_msdw.d_person p
using (person_key)
join prod_msdw.b_procedure b
using (procedure_group_key)
join prod_msdw.v_procedure_control_ref prc
using (procedure_key)
join prod_msdw.d_unit_of_measure u
using (uom_key)
join prod_msdw.d_calendar c
using (calendar_key)
join prod_msdw.d_time_of_day t
using (time_of_day_key)
WHERE m.level1_context_name = 'SCC'
and M.LEVEL2_EVENT_NAME = 'Lab Test'
and m.level3_action_name in ('Corrected Result','Final Result')
and m.level4_field_name in (
    'Clinical Result Numeric',
    'Clinical Result String',
    'Clinical Result Text[01]')
and prc.procedure_type = 'Lab Test'
and prc.procedure_description not in ('CBC & PLT & DIFF','COMP. METABOLIC PANEL', 'REFERRING PHYSICIAN PHONE', 'SEQUENTL INTEGRATED SCR,2');

-- 6. msdw labs with formatted values
create temporary table msdw_labs as
select
    mrn,
    result_date,
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

-- 7. drop labs_msdw work table
drop table labs_msdw;

-- 8. create work table with all labs
create temporary table all_labs as
select * from msdw_labs
union
select * from epic_labs;

-- 9. drop msdw_labs work table
drop table msdw_labs;

-- 10. drop epic_labs work table
drop table epic_labs;

-- 11. insert final labs data into dev_patient_info_pan.all_labs
drop table if exists ${SCHEMA_NAME}.all_labs_prev;

alter table ${SCHEMA_NAME}.all_labs rename to all_labs_prev;

CREATE TABLE IF NOT EXISTS ${SCHEMA_NAME}.all_labs
(
    lab_result_id bigint default "identity"(1211588, 0, ('1,1'::character varying)::text) encode delta32k,
    person_id bigint encode zstd,
    mrn varchar(50) encode zstd,
    result_date timestamp encode zstd,
    value_text varchar(4000) encode zstd,
    value_float numeric(38,4) encode zstd,
    value_range_low numeric(38,4) encode zstd,
    value_range_high numeric(38,4) encode zstd,
    loinc_code varchar(10) encode bytedict,
    loinc_long_name varchar(256) encode zstd,
    loinc_display_name varchar(175) encode zstd,
    unit varchar(20) encode bytedict,
    source_test_name varchar(2000) encode zstd,
    source_value varchar(4000) encode zstd,
    source_value_clean varchar(4000) encode zstd,
    source_value_numeric numeric(38,4) encode zstd,
    source_range_result varchar(4000) encode zstd,
    source_range_value_low varchar(4000) encode zstd,
    source_range_value_high varchar(4000) encode zstd,
    source_op_result varchar(4000) encode zstd,
    source_op_result_operator varchar(2) encode zstd,
    source_op_result_value varchar(4000) encode zstd,
    source_unit varchar(94) encode zstd
)
sortkey(person_id);

insert into ${SCHEMA_NAME}.all_labs
(
    person_id,
    mrn,
    result_date,
    value_text,
    value_float,
    value_range_low,
    value_range_high,
    loinc_code,
    loinc_long_name,
    loinc_display_name,
    unit,
    source_test_name,
    source_value,
    source_value_clean,
    source_value_numeric,
    source_range_result,
    source_range_value_low,
    source_range_value_high,
    source_op_result,
    source_op_result_operator,
    source_op_result_value,
    source_unit
)
select distinct
    p.person_id,
    p.mrn,
    a.result_date,
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
from resource.all_labs a
join prod_references.person_mrns p
using (mrn)
left join loinc l
using (source_code, source_test_name, source_unit)
left join resource.loinc_low_high_values hl
using (loinc_code)
-- only keep valid result values
WHERE value_float IS NULL
OR hl.loinc_code IS NULL
OR (
    value_float IS NOT NULL AND
    hl.loinc_code IS NOT NULL AND
    value_float >= nvl(hl.low_value, value_float) AND
    value_float <= nvl(hl.high_value, value_float)
);


-- 12. drop all_labs work table
drop table all_labs;

-- 13. drop loinc work table
drop table loinc;

-- sanity check
-- 260515532


