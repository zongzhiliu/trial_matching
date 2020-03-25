# deliver the new master sheet
* every different value in inclusion/exclusion as seperate attribute_id
* new attribute_id as PCA000
* change inclusion/exclusion as 0/1
* attribute_match/mandatory as 0/1
* original crit_id to logic_l1_id (or)
```
1) prepare the attribute mapping table, identified with attribute_id, with
 new_attribute_group, new_atttibute_name, new_attribute_value
2) generate the _crit_attribute_used table with updated attribute_group, _name,
3) generate new_attribute_id for each unique attribute_id, ie_value in the trials
    if attribute value in (min, max) 
    assign new_attribute_name as attribute_name+attribute_value
    assign new_attribure_value as ie_value
4)  compile the new crit_attribute with new_attribute_id, old_attribute_id,
    attribute_group, attribute_name, attribute_value, 
    attribute_mandatory, attribute_logic
5) compile the new master_sheet, mapped with attribute_id, including
 new_attribute_id, old_attribute_id, attribute_group, attribute_name, value
 inclusion, exclusion, mandatory, logic
```
