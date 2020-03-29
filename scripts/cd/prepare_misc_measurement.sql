drop table if exists misc_measurement cascade;
create table misc_measurement as
with latest_bmi as (
    select mrn person_id, weight_kg, weight_age
    from (select *, row_number() over (
            partition by mrn
            order by -weight_age, -height_age)
        from vital_bmi)
    where row_number = 1
)
select person_id, 'age' as code
    , datediff(day, date_of_birth, current_date) / 365.25 as value_float
    from demo union all
select person_id, 'latest_bodyweight'
    , weight_kg
    from latest_bmi
;
/*
select code, count(*), count(distinct person_id) from misc_measurement group by code;
select * from misc_measurement order by random() limit 99;
*/
