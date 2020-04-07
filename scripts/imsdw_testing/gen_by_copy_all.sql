------------------------------------------------------------ -- copy the whole tables
create view v_caregiver_control_ref as
select * from prod_msdw.v_caregiver_control_ref
;
create view v_diagnosis_control_ref as
select * from prod_msdw.v_diagnosis_control_ref
;
create view v_procedure_control_ref as
select * from prod_msdw.v_procedure_control_ref
;
create view v_material_control_ref as
select * from prod_msdw.v_material_control_ref
;
create view v_facility_control_ref as
select * from prod_msdw.v_facility_control_ref
;

-- d_metadata, d_unit_of_measure, d_data_state
-- d_time_of_day, d_calendar
create table d_metadata as
select * from prod_msdw.d_metadata
;
create table d_unit_of_measure as
select * from prod_msdw.d_unit_of_measure
;
create table d_data_state as
select * from prod_msdw.d_data_state
;
create table d_calendar as
select * from prod_msdw.d_calendar
;
create table d_time_of_day as
select * from prod_msdw.d_time_of_day
;

