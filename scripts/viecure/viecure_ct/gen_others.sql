create table viecure_ct.all_tumor_marker as
select pt_id person_id
, name test_name
, created_tstamp test_time
, positive_ind
, inactive, errored
from patient_tumor_markers  -- 259	96
join tumor_marker_list tml on tumor_marker_id=tml.id --good
where not nvl(inactive, False) 
    and not nvl(errored, False)
;
