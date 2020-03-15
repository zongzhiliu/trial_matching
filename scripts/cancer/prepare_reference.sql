drop view if exists ref_drug_mapping;
drop view if exists ref_lab_mapping;

create view ref_drug_mapping as
select * from ${ref_drug_mapping}
;
create view ref_lab_mapping as
select * from ${ref_lab_mapping}
;
