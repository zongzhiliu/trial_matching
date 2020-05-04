alter table ref_test rename to _ref_test;
create view ref_test as
select ct_test_name
, unit
, nullif(normal_low, '')::float
, nullif(normal_high, '')::float
from _ref_test
;
