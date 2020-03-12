-- set search_path=ct_pca;
drop table if exists treating_physician_scott cascade;
create table treating_physician_scott as
with visits as (
     select     pm.person_id
     ,          e.encounter_control_key
     ,          max(e.begin_date_time) as enc_date
     ,          vc.first_name || ' ' || vc.last_name as caregiver
     ,          case when o.first_name is not null then 'Y' else 'N' end as oncologist_from_list
     from     cohort c
     join prod_references.person_mrns pm on c.person_id = pm.person_id
     join prod_msdw.d_person dp on dp.medical_record_number = pm.mrn
     join prod_msdw.fact f using (person_key)
     join prod_msdw.d_encounter e using (encounter_key)
     join prod_msdw.d_calendar using (calendar_key)
     join prod_msdw.b_diagnosis bd using (diagnosis_group_key)
     join prod_msdw.v_diagnosis_control_ref vd using (diagnosis_key)
     join prod_msdw.b_caregiver bc using (caregiver_group_key)
     join prod_msdw.v_caregiver_control_ref vc using (caregiver_key)
     left join ct.hema_onco_faculty o
         on o.first_name || ' ' || o.last_name = vc.first_name || ' ' || vc.last_name
     --where pm.person_id in (19, 2396, 4418, 9272, 11392, 14611, 15703, 22034, 32554, 36352)
     where vc.first_name not in ('MSDW_UNKNOWN', 'MSDW_NOT APPLICABLE', 'NOT AVAILABLE')
     group by  pm.person_id
     ,         e.encounter_control_key
     ,         vc.first_name || ' ' || vc.last_name
     ,         case when o.first_name is not null then 'Y' else 'N' end
), freq_all as (
    select person_id
    , caregiver
    , count(*) as num_visits
    from visits
    group by person_id
    , caregiver
) , freq_onc as (
    select person_id
    , caregiver
    , count(*) as num_visits
    from visits
    where oncologist_from_list = 'Y'
    group by person_id
    , caregiver
) , top_cg_all as (
    select person_id
    , f.caregiver
    , c.known_zip
    , f.num_visits
    , row_number() over (partition by f.person_id order by f.num_visits desc) as rn
    from freq_all f
    left join ct.caregiver_name_zip c
        on f.caregiver = c.first_name || ' ' || c.last_name
) , top_cg_onc as (
    select person_id
    , f.caregiver
    , c.known_zip
    , f.num_visits
    , row_number() over (partition by f.person_id order by f.num_visits desc) as rn
    from freq_onc f
    left join ct.caregiver_name_zip c
        on f.caregiver = c.first_name || ' ' || c.last_name
)
select  c.person_id
,       coalesce(o.caregiver, a.caregiver) as caregiver
,       coalesce(o.known_zip, a.known_zip) as zip_code
,       coalesce(o.num_visits, a.num_visits) as num_visits
from    cohort c
left join (select * from top_cg_all where rn = 1) a
    on      c.person_id = a.person_id
left join (select * from top_cg_onc where rn = 1) o
    on      c.person_id = o.person_id;
