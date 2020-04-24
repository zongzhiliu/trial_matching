/*** match performance
Requires: latest_ecog, _karnofsky
, crit_attribute_used (using attribute_id, _value)
Results: _p_a_ecog, _karnofsky
*/
-- ecog from latest_ecog
drop table if exists _p_a_ecog cascade;
create table _p_a_ecog as
select person_id, ecog_ps as patient_value
, attribute_id
, patient_value=attribute_value::int as match
from latest_ecog
cross join crit_attribute_used
where attribute_id between 9 and 14
;

create view qc_match_ecog as
select attribute_name, attribute_value, count(*)
from _p_a_ecog join crit_attribute_used using (attribute_id)
where match
group by attribute_name, attribute_value
;

-- karnofsky
drop table if exists _p_a_karnofsky cascade;
create table _p_a_karnofsky as
select person_id, karnofsky_pct as patient_value
, attribute_id
, patient_value=attribute_value::int as match
from latest_karnofsky
cross join crit_attribute_used
where attribute_id between 16 and 21 --lower(attribute_name)='karnofsky'
;

create view qc_match_karnofsky as
select attribute_name, attribute_value, count(*)
from _p_a_karnofsky join crit_attribute_used using (attribute_id)
where match
group by attribute_name, attribute_value
;
