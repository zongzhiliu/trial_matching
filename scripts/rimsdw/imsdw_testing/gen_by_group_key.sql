------------------------------------------------------------ 
-- filter by group_key
create table b_diagnosis as
select t.* from prod_msdw.b_diagnosis t
join fact using (diagnosis_group_key);

create table b_material as
select t.* from prod_msdw.b_material t
join fact using (material_group_key);

create table b_procedure as
select t.* from prod_msdw.b_procedure t
join fact using (procedure_group_key);

create table b_caregiver as
select t.* from prod_msdw.b_caregiver t
join fact using (caregiver_group_key);

create table b_accounting as
select t.* from prod_msdw.b_accounting t
join fact using (accounting_group_key);

create table b_organization as
select t.* from prod_msdw.b_organization t
join fact using (organization_group_key);

create table b_payor as
select t.* from prod_msdw.b_payor t
join fact using (payor_group_key);

