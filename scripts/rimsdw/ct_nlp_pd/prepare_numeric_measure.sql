

create table numeric_measurement as (
    select person_id, 'age' as code
    , datediff(year, date_of_birth, CURRENT_DATE) as value_float
    from demo
    union select person_id, 'ecog', ecog_ps
    from latest_ecog
    union select person_id, 'karnosky', karnofsky_pct
    from latest_karnofsky
    union select person_id, 'lot', n_lot
    from lot
);
