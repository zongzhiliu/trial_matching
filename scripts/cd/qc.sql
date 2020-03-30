/* CD patient with complications
IBD026	CD of Small Intestine, with Complication	Yes	5,751
IBD028	CD of Large Intestine, with Complication	Yes	5,444
*/
with pa_match as (
	select person_id, attribute_id
	, bool_or(match) as match
	from _p_a_t_diagnosis
	where attribute_id in ('IBD026', 'IBD028')
	group by person_id, attribute_id
), p_match as (
	select bool_or(match) as match
	from pa_match
	group by person_id
)
select count(*) from p_match where match
;
    -- 7080

/* UC with complications
IBD036    Ulcerative Proctitis with Complication    Yes    3,188
*/
with pa_match as (
	select person_id, attribute_id
	, bool_or(match) as match
	from _p_a_t_diagnosis
	where attribute_id in ( 'IBD034', 'IBD036', 'IBD038', 'IBD041')
	group by person_id, attribute_id
), p_match as (
	select bool_or(match) as match
	from pa_match
	group by person_id
)
select count(*) from p_match where match
;
    -- 3188

select * from crit_attribute_used where attribute_id ~ 'IBD06[0-6]';

/* procedure matching with ICD vs CPT
IBD062	Ileostomy	Yes	cpt_mapping	706
IBD060	Stoma	Yes	icd_rex	1,037

attribute_id	attribute_name	attribute_value	code_type	true_patients
IBD065	Acquired Absence of GI Tract	Yes	icd_rex	1,386
IBD064	Anastomosis	Yes	icd_rex	690
IBD066	Colectomy	Yes	cpt_mapping	1,929
*/
with pat_match as (
    select person_id, attribute_id, trial_id, match from _p_a_t_diagnosis union all
    select person_id, attribute_id, trial_id, match from _p_a_t_procedure
),  pa_match as (
	select person_id, attribute_id
	, bool_or(match) as match
	from pat_match
	where attribute_id in ( 'IBD060', 'IBD062')
	group by person_id, attribute_id
), p_match as (
	select bool_and(match) as match
	from pa_match
	group by person_id
)
select count(*) from p_match where match
;
    -- 356
with pat_match as (
    select person_id, attribute_id, trial_id, match from _p_a_t_diagnosis union all
    select person_id, attribute_id, trial_id, match from _p_a_t_procedure
),  pa_match as (
	select person_id, attribute_id
	, bool_or(match) as match
	from pat_match
	where attribute_id ~ 'IBD06[456]'
	group by person_id, attribute_id
), p_match_cpt as (
	select person_id, bool_or(match) as match
	from pa_match
    where attribute_id ~ 'IBD066'
	group by person_id
), p_match_icd as (
	select person_id, bool_or(match) as match
	from pa_match
    where attribute_id ~ 'IBD06[45]'
	group by person_id
), p_match as (
    select person_id, bool_and(match) as match
    from ( select person_id, match from p_match_cpt union all
        select person_id, match from p_match_icd)
    group by person_id
)
--select count(*) from p_match_cpt where match; --1929
--select count(*) from p_match_icd where match; --1767
select count(*) from p_match where match --631
;


/*********
 * explore
 */
select * from _kinds_of_procedures
where lower(procedure_description) ~
--'transfusion'
'stem cell'
--'pluripotent'
;

create table _kinds_of_rx_ as
select rx_name, rx_generic, context_material_code, context_name, count(*) records
from _rx
group by rx_name, rx_generic, context_material_code, context_name
; -- code is not helpfule
select * from _kinds_of_rx_ order by rx_name, rx_generic, context_name, context_material_code;

create table _kinds_of_rx as
select rx_name, rx_generic, count(*) records
from rx
group by rx_name, rx_generic
;
select * from _kinds_of_rx
where lower(rx_name || '; ' || rx_generic) ~
'hydroxy'
;
select * from dx
where lower(description) ~ 'alcohol abuse'
;

drop table _kinds_of_icds;
create table _kinds_of_icds as
select context_name, context_diagnosis_code, description
, count(*) records
from dx
where description != 'NOT AVAILABLE'
group by context_name, context_diagnosis_code, description
;
grant all on schema ct_scd to wen_pan;
select * from dmsdw_2019q1.d_person limit 10;

