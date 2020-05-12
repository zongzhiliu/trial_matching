/***
Dependencies: 
  demo_plus, date_of_birth, 
, latest_ecog: ecog
, latest_karnofsky: karnosky
, lot: lot
Results:
	numeric_measurement
*/
create table numeric_measurement as (
    select person_id, 'age' as code
    , datediff(year, date_of_birth, CURRENT_DATE) as value_float
    from demo_plus
    union select person_id, 'ecog', ecog_ps
    from latest_ecog
    union select person_id, 'karnofsky', karnofsky_pct
    from latest_karnofsky
    union select person_id, 'lot', n_lot
    from lot
);
