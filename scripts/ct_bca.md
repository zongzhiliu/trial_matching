# repopulate the ct_bca schema
* alterations later
* set search_path to psql_w_envs??
```
psql -c "create schema if not exists ct_${cancer_type}"
```

## dbeaber settings
```
@set cancer_type=BCA
@set cancer_type_icd=^(C50|17[45])
@set working_schema=ct_${cancer_type}
@set last_visit_within=99
@set ref_drug_mapping=ct.drug_mapping_cat_expn4_20200313
@set ref_lab_mapping=ct.ref_lab_loinc_mapping
set search_path=ct_${cancer_type};
```

## debug
```sql
select * from trial_attribute_used
where attribute_id='BCA109'
;


select person_id, gene, variant_type, variant, reported_occurrence_type
from cohort
join cplus_from_aplus.genetic_test_occurrences using (person_id)
join cplus_from_aplus.variant_occurrences using (genetic_test_occurrence_id)
join cplus_from_aplus.target_genes using (target_gene_id)
where is_clinically_significant
    and gene ~'^FGFR'
;
```
