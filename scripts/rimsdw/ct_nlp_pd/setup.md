## setup the schema
```sql
create schema ct_nlp_pd;
ALTER DEFAULT PRIVILEGES IN SCHEMA ct_nlp_pd GRANT ALL on tables to mingwei_zhang;
```

## Compile the entities from NLP
* cat result files with the file prefix as trial_index column
```bash
cd '/Users/zongzhiliu/Downloads/Split NCT-IE Clamp Results'
head -n1 NCT02221739-New-IC.txt | gsed 's/^/trial_index\t/' | gsed 's/Start/iStart/;s/End/iEnd/' > res.tsv
for f in *.txt; do
    #a=${f%%-*.txt};
    a=${f%%.txt};
    cat $f | gsed '1d' | gsed "s/^/$a\t/" >>res.tsv; 
done
```
* extract trial_id, subset, inc/exc from file name
```ipython
df = pd.read_csv('res.tsv', delimiter='\t', encoding='latin1')
df['trial_id'] = [x.split('-')[0] for x in df.trial_index]
df['subset'] = [x.split('-')[1] for x in df.trial_index]
tmp = [x.split('-')[-1] for x in df.trial_index]
df['ie_flag'] = ['IC-EC' if x not in ('EC', 'IC') else x for x in tmp]
df.to_csv('PD_trial_entity_20200507.csv' , index=False)
```

* trials with mapped attribute_id
```
cd /Users/zongzhiliu/Sema4/rimsdw/ct_nlp_pd/
trial_entity = pd.read_csv('PD_trial_entity_20200507.csv')
entity = pd.read_csv('PD_entity_raw_20200507.csv')
mapped_entity = entity[entity.attribute_id.notnull()]
trial_attr = trial_entity.merge(mapped_entity, on=['Semantic', 'Entity'])[['trial_id', 'subset', 'ie_flag', 'attribute_id']]
conn = sqlite3.connect(':memory:')
trial_attr.to_csv('PD_trial_attr_gene_alteration.csv', index=False)

# summary
trial_attr.to_sql('trial_attr', conn, index=False, if_exists='replace')
pd.read_sql("""
    select attribute_id, ie_flag
    , count(distinct trial_id)
    from trial_attr
    group by attribute_id, ie_flag
    """, conn).to_csv('qc_trial_attr_gene_alteration.csv')
pd.read_sql("""
    select ie_flag
    , count(distinct trial_id)
    from trial_attr
    group by ie_flag
    """, conn)
```
* have the attributes coded (0511)
* load the updated drug_mapping table (v7)
* load the coded attribute table
* update the nsclc_histology_mapping (done)

* set up the pipeline ana start matching

## next
