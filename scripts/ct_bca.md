# repopulate the ct_bca schema
For breast cancer trials.
Without limitation to the date of last visit.

# test

## run the pipeline
```
source bca/import.sh
```
## input format
* trial_attribute: [inclusion,M,exclusion] for each trial
    * ie (bool): inclusion/exclusion
    * ie_value: value in inclusion/exclusion; could be transformed during conversion.

* crit_attribute: [code_type, code_raw, code_ext, attribute_value, attribute_mandatated]
    * code_type: how to match using code_raw, code_ext, attribute_value, ie_value
    * attributes with code_type empty or '-' will be filtered off
    * code_raw, code_ext: could be transformed to code during the conversion

## attributes cumstomarization
* BCA30    Low -> Equivalent

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
-- prepare_lot
select count(distinct person_id) from lot where n_lot>0;
select count(distinct person_id) from modality_lot where n_lot>0;
    -- 5765, 5765
select modality, count(distinct person_id) patients
from modality_lot
where n_lot>0
group by modality
;
select n_lot, count(distinct person_id)
from lot
group by n_lot
order by n_lot
;
-- match drug
select attribute_id, attribute_name, match
, count(distinct person_id) patients
from _p_a_rxnorm
join crit_attribute_used using (attribute_id)
where match
group by attribute_id, attribute_name, match
order by attribute_id, match
;

-- stage matching
select attribute_id, attribute_name, code, attribute_value,  match
, count(distinct person_id) patients
from _p_a_t_stage
join crit_attribute_used using (attribute_id)
where match
group by attribute_id, attribute_name, code, attribute_value, match
order by attribute_id, attribute_name, match
;
-- Not all BCA patients with BCA ICD?
with tmp as (
select count(distinct person_id) --, date_of_birth, gender_name, date_of_death, race_name, ethnicity_name
from cplus_from_aplus.cancer_diagnoses cd
join prod_references.cancer_types using (cancer_type_id)
join prod_references.people p using (person_id)
join prod_references.genders g using (gender_id)
join prod_references.races r using (race_id)
join prod_references.ethnicities using (ethnicity_id)
--join cplus_from_aplus.visits using (person_id)
where --nvl(cd.status, '') != 'deleted' and nvl(p.status, '') != 'deleted'
    --and date_of_death is NULL
    --and datediff(day, visit_date, current_date)/365.25 <= 99
    cancer_type_name='${cancer_type}'
    --13241
 )
 select count(distinct person_id)
 from tmp
 join prod_references.person_mrns using(person_id)
 join dev_patient_info_bca.all_diagnosis ad on medical_record_number = mrn
 where context_diagnosis_code ~ '^(C50|17[45])'
; --13038
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
    * using all but exon 20 insertion
EGFR: R108K, R222C, A289T, P596L, G598V, Exon 20 insertion, E709K, G719X, V742I, E746_A750del, S768I, V769M, V774M, R831C, R831H, L858R, L861Q, A864V
    * using all clinical significant molecular variants
```
