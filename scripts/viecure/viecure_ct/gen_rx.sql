set search_path=viecure_emr;

-- select count(*), count(distinct id), count(distinct patient_id) from patient_medications_current; --315899	16759
-- select count(*), count(distinct id), count(distinct patient_id) from mar;  --2382760	30590
create table viecure_ct.all_rx as
with me as (
	select distinct patient_id person_id
	, 'med' as source_type
	, 'fdb' code_type, code rx_code
	, description rx_name
	, start_date start_time
	, is_error_ind error_ind
	from patient_medications_current
	where not nvl(error_ind, False)
), ma as (
	select distinct patient_id person_id
	, 'mar' as source_type
	, 'fdb' code_type, fdb_id rx_code
	, drug_name rx_name
	, drug_admin_start_time start_time
	, error_ind
	from mar
	where not nvl(error_ind, False)
)
-- select count(*), count(distinct person_id) from ma; --2360336	30590
-- select count(*), count(distinct person_id) from me; --312406	16759
select * from me union
select * from ma
;
select count(*), count(distinct person_id) from viecure_ct.all_rx; -- 2672742	36063
