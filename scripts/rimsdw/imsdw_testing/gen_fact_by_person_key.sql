--set search_path=imsdw_testing;
------------------------------------------------------------
-- filter by person_key
create table fact as
select t.* from prod_msdw.fact t
join d_person using (person_key);
/*
select count(*), count(distinct person_key)
from fact;
    -- 6629289 | 47522
    -- ?? 20% of person_key do not have a fact
    -- avg 100 fact for each person_key
*/

create table fact_lab as
select t.* from prod_msdw.fact_lab t
join d_person using (person_key);

create table fact_eagle as
select t.* from prod_msdw.fact_eagle t
join d_person using (person_key);

