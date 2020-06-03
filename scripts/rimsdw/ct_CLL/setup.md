#
## set up drug references
```ipython pandas 1.0.3
working_dir='/Users/zongzhiliu/Sema4/rimsdw/ct_CLL'
df = pd.read_csv('drug_mapping_BTKi.csv', index_col=0)
tmp = df.other_names.apply(lambda x: [i.strip() for i in x.split(';')])
tmp.explode().to_csv('drug_alias_BTKi.csv')
```
## cohort, dx, rx
```sql
set search_path=ct_cll;
create table _cll_dx_strict as
    select medical_record_number mrn
    , context_diagnosis_code icd, calendar_date as dx_date
    from prod_msdw.d_person
    join prod_msdw.fact using(person_key)
    join prod_msdw.d_metadata using (meta_data_key)
    join prod_msdw.d_calendar using (calendar_key)
    join prod_msdw.b_diagnosis using (diagnosis_group_key)
    join prod_msdw.v_diagnosis_control_ref using (diagnosis_key)
    where person_key>3 and data_state_key=1
        and context_name like 'ICD%'
        and meta_data_key in (3490, 5719)  --OR (F.META_DATA_KEY = 5719
        and context_diagnosis_code ~'^(C91[.]?1|204[.]?1)'
;
create table cohort as select distinct mrn from _cll_dx;
select count(*) from cohort;
    --2779 the same

select count(distinct mrn) from _cll_dx_strict;
    --1832
create view qc_cohort as
select icd
    , count(*) records, count(distinct mrn) patients
from _cll_dx
group by icd
order by icd
;
    --improved: a few invalid records excluded.

create temporary table _person as
select person_key, mrn
from cohort join prod_msdw.d_person on mrn=medical_record_number
;

drop table dx cascade;
create table dx as
    select distinct mrn
    , context_diagnosis_code icd, calendar_date as dx_date
    from _person
    join prod_msdw.fact using(person_key)
    join prod_msdw.d_calendar using (calendar_key)
    join prod_msdw.b_diagnosis using (diagnosis_group_key)
    join prod_msdw.v_diagnosis_control_ref using (diagnosis_key)
    where person_key>3 and data_state_key=1
        and context_name like 'ICD%'
;

drop table if exists latest_dx cascade;
create table latest_cll_dx as (
    select mrn, icd, dx_date
    , case when icd ~ '0$' then 'no_remission'
        when icd ~ '12$' then 'refactory'
        when icd ~ '[.1]11$' then 'remission'
        end latest_status
    from (select *, row_number() over (
            partition by mrn --, icd
            order by dx_date, icd)
        from dx
        where icd ~'^(C91[.]?1|204[.]?1)'
        )
    where row_number=1
);

create view qc_lastest_cll_dx as
select latest_status, count(*) records, count(distinct mrn) patients
-- from latest_cll_dx join (select distinct mrn from rx) using (mrn)
from latest_cll_dx
group by latest_status --icd
order by latest_status --icd
;
    -- improved
```
## rx
```sql
drop table if exists rx cascade;
create table rx as
select distinct mrn, calendar_date as rx_date
, material_name as rx_name
, generic_name as rx_generic
, nvl(material_name, '_')+'| '+nvl(generic_name, '_')+'| '+nvl(brand1, '_')+'| '+nvl(brand2, '_') as rx_title
from _person
join prod_msdw.fact using (person_key)
join prod_msdw.d_calendar using (calendar_key)
join prod_msdw.d_metadata using (meta_data_key)
join prod_msdw.b_material using (material_group_key)
join prod_msdw.v_material_control_ref using (material_key)
where data_state_key=1
    and material_type = 'Drug'
    /*and meta_data_key in (3810,3811,3814,4781,4788,4826,5100,5115,5130,5145,
        2573,2574,4819,4814,4809,4804,5656,5655,5653,5649,2039,2040,2041,2042,
        5642,5643,5645,4802,4803,4805)
    */
;

select count(*) records, count(distinct mrn) patients
from rx;
    -- 883699 |     2705
    /* the following are excluded
    | GCO#13-0728 IBRUTINIB (PCI-32765) 140 MG CAPSULE| _| _| _     | 175       | 4          |
    | GCO#13-1980 IBRUTINIB (PCI-32765) 140 MG CAPSULE| _| _| _     | 724       | 13         |
    | GCO#14-0558 IBRUTINIB (PCI-32765)/PLACEBO| _| _|

create view _rx_strict as
select distinct mrn, calendar_date as rx_date
, nvl(material_name, '_')+'| '+nvl(generic_name, '_')+'| '+nvl(brand1, '_')+'| '+nvl(brand2, '_') as rx_title
from _person
join prod_msdw.fact using (person_key)
join prod_msdw.d_calendar using (calendar_key)
join prod_msdw.d_metadata using (meta_data_key)
join prod_msdw.b_material using (material_group_key)
join prod_msdw.v_material_control_ref using (material_key)
where data_state_key=1
    and material_type = 'Drug'
    and level1_context_name = 'EPIC'
    and level2_event_name in ('Prescription','Medication Administration'
    , 'Medication Order', 'Medication Reported')
;
select count(*) records, count(distinct mrn) patients
from _rx_strict;
    -- 598928 |     2349
```

## rx drug mapping
```
#load_into_db_schema_some_csvs.py rimsdw ct_CLL drug_mapping_BTKi.csv
#load_into_db_schema_some_csvs.py rimsdw ct_CLL drug_alias_BTKi.csv

drop table if exists source_rx cascade;
create table source_rx as
select rx_title
, count(*) records, count(distinct mrn) patients
from rx
group by rx_title
;

drop table if exists rx_drug cascade;
create table rx_drug as
with drug_alias as (
    select drug_name, other_names alias from drug_alias_btki union
    select drug_name, drug_name from drug_alias_btki
)
select distinct drug_name, rx_title
from source_rx
join drug_alias on ct.py_contains(rx_title, '\\b'+alias+'\\b', 'i')
order by drug_name, rx_title
;
select * from rx_drug order by rx_title; --where drug_name is not null;
    -- quite a few rx_title filtered by the metadata_key picking

create or replace view qc_rx_drug_precision as
select rx_title, drug_name
, other_names
, records, patients
, null::bool is_valid
from source_rx
join rx_drug using (rx_title)
join drug_mapping_btki using (drug_name)
order by drug_name, lower(rx_title)
;

create or replace view qc_rx_drug_recall as
select rx_title
, records, patients
, null::varchar drug_name_rescued
from source_rx
left join rx_drug using (rx_title)
left join drug_mapping_btki using (drug_name)
where drug_name is null
order by lower(rx_title)
;
```
## BTKi distribution
```sql
-- patients treated with BTKi
create temporary table _cohort_treated as
select distinct mrn
from cohort
join rx using (mrn)
join rx_drug using (rx_title)
join drug_mapping_btki using (drug_name)
;
select count(*) from _cohort_treated;
-- 165 != 279: with metadata_key filtering
-- 281 with material_type filtering only

select latest_status
, count(*) records, count(distinct mrn) patients
from latest_cll_dx join _cohort_treated using (mrn)
-- from latest_cll_dx
group by latest_status --icd
order by latest_status --icd
;

-- stratified by BTKi drug name
create view qc_drug_distribution as
with latest_drug as (
    select mrn, drug_name, rx_date
    from (select *, row_number() over (
            partition by mrn
            order by rx_date desc nulls last, drug_name)
        from rx
        join rx_drug using (rx_title))
    where row_number=1
)
-- select * from latest_drug limit 9;
select latest_status, drug_name latest_drug_name
, count(distinct mrn) patients
from latest_cll_dx join latest_drug using (mrn)
group by latest_status, drug_name --icd
order by latest_status, drug_name --icd
;
    -- improved
```
## BTKi duration
```sql
create view qc_btki_duration as
with latest_btki as (
    select mrn, drug_name, rx_date
    from (select *, row_number() over (
            partition by mrn
            order by rx_date desc nulls last, drug_name)
        from rx
        join rx_drug using (rx_title))
    where row_number=1
), earliest_btki as (
    select mrn, drug_name, rx_date
    from (select *, row_number() over (
            partition by mrn
            order by rx_date, drug_name)
        from rx
        join rx_drug using (rx_title))
    where row_number=1
)
select mrn
, earliest_btki.drug_name drug_earliest
, earliest_btki.rx_date date_earliest
, latest_btki.drug_name drug_latest
, latest_btki.rx_date date_latest
, datediff(day, date_earliest, date_latest) btki_durated_days
from earliest_btki join latest_btki using (mrn)
order by btki_durated_days desc nulls last
;
```
## plot the BTK duration
* a customarized histogram (0, <3m, 3-6M, 6M-5Y, >=5Y)
```ipython
os.chdir(working_dir)
df = pd.read_csv('qc_btki_duration_202005271316.csv') 
x = df.btki_durated_days
#np.log10(x).plot(kind='kde')
#np.log10(x).plot(kind='hist')
plt.hist(x)
plt.hist(x, bins=[0, 0.5, 90, 180, 365*5, max(x)])

bb = pd.read_csv('drug_duration_bin_30.csv')

from pandasql import sqldf
query = """select bin_label, count(*) patients
    from df join bb
        on btki_durated_days between bin_start and bin_stop
    group by bin_label
    order by bin_id
    """
res = sqldf(query, globals())
res.plot(kind='bar')
plt.xticks(range(res.shape[0]), labels=res.bin_label)
plt.savefig('tmp.png')
res.to_csv('patients_by_bins_30.csv', index=False)
```
