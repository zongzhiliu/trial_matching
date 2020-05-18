/***
Dependencies: ref tables
, trial_attribute_raw
, crit_attribute_raw: attribute_id, attribute_g/n/v
, crit_attribute_mapping: attribute_id, new_attribute_g/n/v, logic_default, mandatory_default
Results:
    trial_attribute_used
    crit_attribute_used
    _crit_attribute_mapped
create or replace view ref_drug_mapping as
select * from ${ref_drug_mapping}
; --ct.drug_mapping_cat_expn3;

drop view if exists ref_histology_mapping;
create view ref_histology_mapping as
select * from ${ref_histology_mapping}
;
*/
set search_path=ct_CLL;
create view latest_icd as select * from viecure_ct.latest_icd;
-- later: add CLL to ref_cancer_icd
drop table if exists cohort cascade;
create table cohort as
select distinct person_id
from viecure_ct.latest_icd
join viecure_ct.demo_plus using (person_id)
where dx_code ~ '${cancer_type_icd}'
    and date_of_death is NULL
    and datediff(day, last_visit_date, '${protocal_date}')/365.25 <= ${last_visit_within}
;

select dx_code
    , count(*) records, count(distinct person_id) patients
from cohort
join latest_icd using (person_id)
where dx_code ~ '${cancer_type_icd}'
group by dx_code
order by dx_code
;

select rx_name
    , count(*) records, count(distinct person_id) patients
from cohort
join viecure_ct.all_rx using (person_id)
where lower(rx_name) ~ '(^|\\W)(ibrutinib|pci-32765|cra-032765|imbruvica|ibrutix)(\\W|$)'
group by rx_name
order by rx_name
;
with dx as (
    select person_id, dx_code icd
    from cohort
    join latest_icd using (person_id)
    where dx_code ~ '${cancer_type_icd}'
), rx as (
    select distinct person_id, rx_name
    from cohort
    join viecure_ct.all_rx using (person_id)
    where lower(rx_name) ~ '(^|\\W)(ibrutinib|pci-32765|cra-032765|imbruvica|ibrutix)(\\W|$)'
)
select case when icd ~ '0$' then 'no_remission'
    when icd ~ '12$' then 'refactory'
    when icd ~ '[.1]11$' then 'remission'
    end latest_status
, count(*) records, count(distinct mrn) patients
from dx join rx using (person_id)
group by latest_status
order by latest_status
;

/* later
drop view if exists _crit_attribute_raw cascade;
create view _crit_attribute_raw as
select attribute_id
, attribute_group
, nvl(attribute_name, '_') attribute_name
, nvl(attribute_value, '_') attribute_value -- quickfix
, code_type
, nvl(code_base, '_') code_raw
, code_ext
, code_transform
, case when code_type like 'icd%' then
        replace('^('+code_raw+'|'+nvl(code_ext, '__')+')', '.', '[.]') -- quickfix code_ext null
    when code_type like 'gene%' then
        '^('+code_raw+')$'
    when code_type in ('drug_name') then
        lower(code_raw)
    else code_raw
    end code
from ${crit_attribute}
;

select ct.assert(count(*) = count(distinct attribute_id)
, 'attribute_id should be unique') from _crit_attribute_raw
;
select ct.assert(bool_and(attribute_group+attribute_name+attribute_value is not null)
, 'each attribute should have nonempty group, name, value') from _crit_attribute_raw
;

drop view if exists _crit_attribute_mapped;
create view _crit_attribute_mapped as
select attribute_id
, new_attribute_group attribute_group
, new_attribute_name attribute_name
, new_attribute_value attribute_value
, logic_default
, mandatory_default
from ${crit_attribute_mapping}
;
select ct.assert(count(*) = count(distinct attribute_id)
, 'attribute_id should be unique') from _crit_attribute_mapped;
select ct.assert(bool_and(attribute_group+attribute_name+attribute_value is not null)
, 'each attribute should have nonempty group, name, value') from _crit_attribute_mapped
;

create or replace view _trial_attribute_raw as
select * from ${trial_attribute}
;
select ct.assert(bool_and(inclusion is null or exclusion is null)
, 'one of inc/exc must be null') from _trial_attribute_raw
;
select ct.assert(count(distinct btrim(trial_id) + '| ' + attribute_id) = count(*)
, 'trial attribute should be unique') from _trial_attribute_raw
;

-- trial_attribute_used
drop table if exists trial_attribute_used cascade;
create table trial_attribute_used as
select btrim(trial_id) trial_id
, attribute_id
, inclusion is not null as ie_flag
, btrim(nvl(inclusion, exclusion)) ie_value
from  _trial_attribute_raw
where ie_value is not null
;
--    and ie_value !~ 'yes <[24]W' --quickfix

drop view if exists qc_attribute_summary;
create view qc_attribute_summary as
with tmp as (
    select attribute_id, ie_value
    , count(trial_id) trials
    , listagg(distinct ie_flag::int) within group (order by ie_flag::int desc) ie_flags
    from trial_attribute_used
    group by attribute_id, ie_value
)
select attribute_id, ie_value, ie_flags, trials
, attribute_group + '| ' + attribute_name + '| ' + attribute_value attribute_gnv
from tmp join _crit_attribute_raw a using (attribute_id)
order by attribute_id, ie_value
;

-- crit_attribute_used
drop table if exists crit_attribute_used cascade;
create table crit_attribute_used as
select attribute_id, attribute_group, attribute_name, attribute_value
, code_type, code, code_ext, code_transform
from _crit_attribute_raw c
join (select distinct attribute_id
    from trial_attribute_used) using (attribute_id)
;
select count(*) from crit_attribute_used;
*/
