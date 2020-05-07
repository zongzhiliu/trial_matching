drop view latest_icd;
create view latest_icd as
select *, dx_code as icd_code
from viecure_ct.latest_icd;
