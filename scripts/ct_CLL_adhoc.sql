set search_path=prod_msdw;
select * from d_metadata
where META_DATA_KEY in (3490, 5719)
;

with tmp as (
    select medical_record_number mrn
    , context_diagnosis_code icd
    from  d_person
    join fact using(person_key)
    join b_diagnosis using (diagnosis_group_key)
    join v_diagnosis_control_ref using (diagnosis_key)
    where context_name like 'ICD%'
        and context_diagnosis_code similar to '(C91.?1|204.?1)%'
        --and context_diagnosis_code similar to '(C91.1|204.1)%'
)
/*
select icd
    , count(*) records, count(distinct mrn) patients
from tmp
group by icd
order by icd
;
*/
select 'total'
    , count(*) records, count(distinct mrn) patients
from tmp
    --total |  156122 |     2557
    --total |  150709 |     2546 if require .
;
/*
  icd   | records | patients
--------+---------+----------
 204.1  |      24 |        3
 204.10 |   49491 |     1781
 204.11 |    9269 |      528
 204.12 |    1219 |       41
 C91.1  |     170 |        4
 C91.10 |   75962 |     1602
 C91.11 |   13253 |      518
 C91.12 |    1321 |       47
 C911   |      17 |        2
 C9110  |    4505 |      448
 C9111  |     749 |      126
 C9112  |     142 |       19
*/
with tmp as (
    select medical_record_number mrn
    , nvl(material_name, '_')+'| '+nvl(generic_name, '_')+'| '+nvl(brand1, '_')+'| '+nvl(brand2, '_') as material_title
    from  d_person
    join fact using(person_key)
    join b_material using (material_group_key)
    join v_material_control_ref using (material_key)
    where lower(material_title) ~ '(^|\\W)(ibrutinib|pci-32765|cra-032765|imbruvica|ibrutix)(\\W|$)'
)
/*
select material_title
, count(*) records, count(distinct mrn) patients
from tmp
group by material_title
order by material_title
;
*/
select count(*) records, count(distinct mrn) patients
from tmp;
    -- 11264 |      422
/*
                      material_title                       | records | patients
-----------------------------------------------------------+---------+----------
 GCO#13-0728 IBRUTINIB (PCI-32765) 140 MG CAPSULE| _| _| _ |     175 |        4
 GCO#13-1980 IBRUTINIB (PCI-32765) 140 MG CAPSULE| _| _| _ |     724 |       13
 GCO#14-0558 IBRUTINIB (PCI-32765)/PLACEBO| _| _| _        |     136 |        4
 GCO#15-2018 IBRUTINIB 140 MG CAPSULES| _| _| _            |     528 |        9
 GCO#15-2243 IBRUTINIB (IMBRUVICA) 140 MG CAPSULE| _| _| _ |      87 |        4
 GCO#16-1867 IBRUTINIB 140 MG CAPSULE| _| _| _             |     361 |        9
 IBRUTINIB 140 MG CAPSULE| IBRUTINIB| _| _                 |    5930 |      254
 IBRUTINIB 140 MG TABLET| IBRUTINIB| _| _                  |     390 |       31
 IBRUTINIB 280 MG TABLET| IBRUTINIB| _| _                  |     257 |       17
 IBRUTINIB 420 MG TABLET| IBRUTINIB| _| _                  |    1477 |       73
 IBRUTINIB 560 MG TABLET| IBRUTINIB| _| _                  |     453 |       17
 IBRUTINIB 70 MG CAPSULE| ibrutinib| _| _                  |      27 |        1
 IBRUTINIB ORAL| IBRUTINIB| _| _                           |      25 |        7
 IBRUTINIB| _| _| _                                        |      13 |        5
 IMBRUVICA 140 MG CAPSULE| IBRUTINIB| _| _                 |     213 |       29
 IMBRUVICA 140 MG TABLET| IBRUTINIB| _| _                  |      25 |        6
 IMBRUVICA 280 MG TABLET| IBRUTINIB| _| _                  |      55 |        8
 IMBRUVICA 420 MG TABLET| IBRUTINIB| _| _                  |     284 |       25
 IMBRUVICA 560 MG TABLET| IBRUTINIB| _| _                  |      17 |        3
 IMBRUVICA ORAL| IBRUTINIB| _| _                           |      87 |       24
 */
with dx as (
    select medical_record_number mrn
    , context_diagnosis_code icd
    from  d_person
    join fact using(person_key)
    join b_diagnosis using (diagnosis_group_key)
    join v_diagnosis_control_ref using (diagnosis_key)
    where context_name like 'ICD%'
        and context_diagnosis_code similar to '(C91.?1|204.?1)%'
        --and context_diagnosis_code similar to '(C91.1|204.1)%'
), rx as (
    select medical_record_number mrn
    , nvl(material_name, '_')+'| '+nvl(generic_name, '_')+'| '+nvl(brand1, '_')+'| '+nvl(brand2, '_') as material_title
    from  d_person
    join fact using(person_key)
    join b_material using (material_group_key)
    join v_material_control_ref using (material_key)
    where lower(material_title) ~ '(^|\\W)(ibrutinib|pci-32765|cra-032765|imbruvica|ibrutix)(\\W|$)'
)
select case when icd ~ '0$' then 'no_remission'
    when icd ~ '12$' then 'refactory'
    when icd ~ '[.1]11$' then 'remission'
    end ever_status
, count(*) records, count(distinct mrn) patients
from dx join rx using (mrn)
group by ever_status --icd
order by ever_status --icd
;
select 'total'
, count(*) records, count(distinct mrn) patients
from dx join rx using (mrn)
-- total | 1902771 |      228
;
/*
 icd   | records | patients
--------+---------+----------
 204.1  |     567 |        1
 204.10 |  560132 |      139
 204.11 |  157929 |       88
 204.12 |   29668 |       14
 C91.1  |    9072 |        1
 C91.10 |  886183 |      212
 C91.11 |  145795 |      107
 C91.12 |   19575 |       13
 C911   |     405 |        1
 C9110  |   82465 |       96
 C9111  |    8261 |       29
 C9112  |    2719 |        5

ever_status |records|patients|
------------|-------|--------|
no_remission|1528780|     220|
refactory   |  51962|      20|
remission   | 311985|     111|
            |  10044|       2|
*/
