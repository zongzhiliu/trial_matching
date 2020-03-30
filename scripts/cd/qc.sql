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


