select datediff(day, '2020-01-01', current_date) as days_to_current_date
, datediff(day, '2020-01-01', '${protocal_date}') as days_to_protocal_date
;
