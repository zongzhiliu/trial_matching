# repopulate the ct_bca schema
For breast cancer trials.

# test

## run the pipeline
```
source bca/import.sh
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

## QC
```sql
-- stage matching
select attribute_id, attribute_name, code, attribute_value,  match
, count(distinct person_id) patients
from _p_a_t_stage
join crit_attribute_used using (attribute_id)
where match
group by attribute_id, attribute_name, code, attribute_value, match
order by attribute_id, attribute_name, match
;
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

## misc notes
```
Activating mutations:
HER2: I655V, V659E, R678Q, V697L, Exon 20 insertion, T733I, L755X, I767M, D769H/N/Y, V773M, V777L/M, L786V, V842I, T862I, L869R
EGFR: R108K, R222C, A289T, P596L, G598V, Exon 20 insertion, E709K, G719X, V742I, E746_A750del, S768I, V769M, V774M, R831C, R831H, L858R, L861Q, A864V
```
