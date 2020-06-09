create table all_tumor_marker as
select pt_id person_id
, name test_name
, created_tstamp test_time
, positive_ind
, inactive, errored
from viecure_emr.patient_tumor_markers  -- 259	96
join viecure_emr.tumor_marker_list tml on tumor_marker_id=tml.id --good
where not nvl(inactive, False) 
    and not nvl(errored, False)
;

create view qc_tumor_marker as
select test_name, count(*) records, count(distinct person_id) patients
from all_tumor_marker
group by test_name
order by patients desc
;

