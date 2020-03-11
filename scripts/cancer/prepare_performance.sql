/*** * performance: no conversions
Requires:
    demo, cplus_from_aplus
Results:
    latest_ecog, latest_karnofsky
 */
drop table if exists latest_ecog;
create table latest_ecog as
select person_id, ecog_ps
, performance_score_date::date as performance_score_date
from (select *, row_number() over (
        partition by person_id
        order by performance_score_date desc nulls last, ecog_ps) --tie-breaker: best performance
    from cplus_from_aplus.performance_scores
    join demo using (person_id)
    where ecog_ps is not null)
where row_number=1
;
--select count (person_id) from latest_ecog where ecog_ps>=3; --55
drop table if exists latest_karnofsky;
create table latest_karnofsky as
select person_id, karnofsky_pct
, performance_score_date::date as performance_score_date
from (select *, row_number() over (
        partition by person_id
        order by performance_score_date desc nulls last, -karnofsky_pct) --tie-breaker: best performance
    from cplus_from_aplus.performance_scores
    join demo using (person_id)
    where karnofsky_pct is not null)
where row_number=1
;
/*qc
select ecog_ps, count(distinct person_id)
from latest_ecog
group by ecog_ps
order by ecog_ps
;
select karnofsky_pct, count(distinct person_id)
from latest_karnofsky
group by karnofsky_pct
order by karnofsky_pct
;
*/

