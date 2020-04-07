/*uc with complications
IBD034    Ulcerative Pancolitis with Complication    Yes    3,558
IBD036    Ulcerative Proctitis with Complication    Yes    3,188
IBD038    Ulcerative Rectosigmoiditis with Complication    Yes    3,173
IBD041    Left Sided Colitis with Complication    Yes    3,116
*/

/***
* master_sheet
*/
select count(*) records
, count(distinct new_attribute_id) attributes
, count(distinct trial_id) trials
, count(distinct person_id) patients
from v_master_sheet_new
;
    -- 10897920  | 97           | 33       | 14080
