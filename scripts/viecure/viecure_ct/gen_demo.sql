CREATE TABLE demo_plus as 
select p.id as patient_id, p.birth_date,
p.sex as gender_name, rl.description as race_name,
el.description as ethnicity_name,
pd.date_of_death,
max(phi.item_start_date) as last_visit_date
FROM viecure_emr.patient p 
LEFT JOIN viecure_emr.patient_demographics pd on p.id = pd.patient_id 
LEFT JOIN viecure_emr.patient_history_items phi on p.id = phi.pt_id
LEFT JOIN viecure_emr.ethnicity_list el on el.id = pd.ethnicity_list_id 
LEFT JOIN viecure_emr.race_list rl on rl.id = pd.race_list_id 
GROUP BY p.id, p.birth_date, p.sex, rl.description, el.description, pd.date_of_death;