/***
Requires:
    crit_attribute_used
    _master_sheet, _crit_attribute_logic
Results:
    trial_patient_match
*/
-- match adjusted with i/e and then mandatory
drop table if exists _ie_match cascade;
create table _ie_match as
select trial_id, person_id, attribute_id
, (inclusion is not null) as ie
, nvl(inclusion, exclusion) as ie_value
, attribute_match
, mandatory
, case when ie then attribute_match
    else not attribute_match
    end as match_adjusted
, nvl(match_adjusted, not mandatory) as match_imputed
from _master_sheet
;
/*
select * from _ie_match
order by person_id, trial_id, attribute_id
limit 100;
*/

-- collase the ie_match to levels of logic
drop table if exists _crit_l1 cascade;
create temporary table _crit_l1 as
with _crit_l2 as (
    select trial_id, person_id, logic_l1, logic_l2
    , bool_and(match_imputed) l2_match
    from _ie_match
    join _crit_attribute_logic using (attribute_id)
    group by trial_id, person_id, logic_l1, logic_l2
)
select trial_id, person_id, logic_l1
, bool_or(l2_match) l1_match
from _crit_l2
group by trial_id, person_id, logic_l1
;
/*
select distinct l1_match from _crit_l1;
*/

-- summary of logic_l1 matches

drop table if exists v_logic_l1_summary;
create table v_logic_l1_summary as
with tp as (
    select trial_id, count(distinct person_id) total_patients
    from _crit_l1
    group by trial_id
)
select logic_l1, trial_id
, sum(l1_match::int) patients
, patients/total_patients::float as perc_matched
from _crit_l1 join tp using (trial_id)
group by trial_id, logic_l1, total_patients
;
/*
select count(*), count(distinct logic_l1), count(distinct trial_id) from v_logic_l1_summary;
    -- different trial using a variety number of logic1s
*/

drop table if exists trial_patient_match cascade;
create table trial_patient_match as
select trial_id, person_id
, bool_and(l1_match) patient_match
from _crit_l1
group by trial_id, person_id
;

drop view if exists v_trial_patient_count cascade;
drop view if exists v_trial_patient_count;
create view v_trial_patient_count as
select trial_id
, sum(patient_match::int) patients
from trial_patient_match
group by trial_id
order by patients desc
;
/*
select * from v_trial_patient_count;
*/
/*ipython
cd {os.environ['working_dir']}
!select_from_db_schema_table.py rdmsdw ${working_schema}.v_logic_l1_summary > v_logic_l1_summary.csv
df = pd.read_csv('v_logic_l1_summary.csv')
res = df.pivot(index='logic_l1', columns='trial_id', values='patients')
res.to_csv('v_logic_l1_summary.pivot_patients.csv')
df.pivot(index='logic_l1', columns='trial_id', values='perc_matched')\
    .to_csv('v_logic_l1_summary.pivot_fraction.csv')
!select_from_db_schema_table.py rdmsdw ${working_schema}.v_trial_patient_count > v_trial_patient_count.csv
*/
