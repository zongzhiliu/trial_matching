drop table if exists misc_measurement cascade;
create table misc_measurement as
select person_id, 'age' as code
    , datediff(day, date_of_birth, '${protocal_date}') / 365.25 as value_float
    from demo union all
select person_id, 'latest_bodyweight'
    , weight_kg
    from latest_bmi
;
/*
select code, count(*), count(distinct person_id) from misc_measurement group by code;
select * from misc_measurement order by random() limit 99;
*/
