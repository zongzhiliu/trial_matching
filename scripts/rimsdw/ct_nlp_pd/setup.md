## setup the schema
```sql
create schema ct_nlp_pd;
ALTER DEFAULT PRIVILEGES IN SCHEMA ct_nlp_pd GRANT ALL on tables to mingwei_zhang;
```

## Compile the entities from NLP
* cat entity result files with the file prefix as trial_index column
```bash
export working_dir='/Users/zongzhiliu/Sema4/rimsdw/ct_nlp_pd/'
cd '/Users/zongzhiliu/Downloads/Split NCT-IE Clamp Results'
head -n1 NCT02221739-New-IC.txt | gsed 's/^/trial_index\t/' | gsed 's/Start/iStart/;s/End/iEnd/' > res.tsv
for f in *.txt; do
    a=${f%%.txt};
    cat $f | gsed '1d' | gsed "s/^/$a\t/" >>res.tsv; 
done
cp res.tsv $working_dir/entity_raw.tsv
```
* cat relationship files with the file prefix as trial_index column
```bash
cd '/Users/zongzhiliu/Downloads/Clinical Trial R1 Relations'
head -n1 NCT02412371-New-IC-relation.txt | gsed 's/^/trial_index\t/' > res.tsv
for f in *.txt; do
    a=${f%%-relation.txt};
    cat $f | gsed '1d' | gsed "s/^/$a\t/" >>res.tsv; 
done
cp res.tsv $working_dir/relation_raw.tsv
cd $working_dir
```

* extract trial_id, subset, inc/exc from file name
```ipython
df = pd.read_csv('entity_raw.tsv', delimiter='\t', encoding='latin1')
df['trial_id'] = [x.split('-')[0] for x in df.trial_index]
df['subset'] = [x.split('-')[1] for x in df.trial_index]
tmp = [x.split('-')[-1] for x in df.trial_index]
df['ie_flag'] = ['IC-EC' if x not in ('EC', 'IC') else x for x in tmp]
df.to_csv('PD_trial_entity_20200514.csv' , index=False)

df = pd.read_csv('relation_raw.tsv', delimiter='\t', encoding='latin1')
df['trial_id'] = [x.split('-')[0] for x in df.trial_index]
df['subset'] = [x.split('-')[1] for x in df.trial_index]
tmp = [x.split('-')[-1] for x in df.trial_index]
df['ie_flag'] = ['IC-EC' if x not in ('EC', 'IC') else x for x in tmp]
df.to_csv('PD_trial_relation_20200514.csv' , index=False)

df.Relation_Type.value_counts()
df.From_Type.value_counts()
```
* combine the primary and secondary entities
```
# primary on the left and secondary on the right
# rename the columns of relation
relation = pd.read_csv('PD_trial_relation_20200514.csv')
entity = pd.read_csv('PD_trial_entity_20200514.csv')
conn = sqlite3.connect(':memory:')
relation.to_sql('relation', conn)
entity.to_sql('entity', conn)
entity_relation = pd.read_sql("""
    select distinct e.*, Relation_Type, From_Type, From_Value
    from entity e join relation using (trial_index, Semantic, Entity)
    """, conn)

entity_relation_mapping = entity_relation[['Semantic', 'Entity', 'Relation_Type', 'From_Type', 'From_Value']].drop_duplicates()
entity_relation_mapping.to_csv('entity_relation_mapping.csv', index=False)
```
* trials with mapped attribute_id
```
# merge the mapped gene mutation and others (with only the PD_attribute1
trial_entity = pd.read_csv('PD_trial_entity_20200514.csv')
mapped_entity = pd.read_csv('entity_mapped_all.csv')
trial_attr = trial_entity.merge(mapped_entity, on=['Semantic', 'Entity'])[['trial_id', 'subset', 'ie_flag', 'attribute_id']]
trial_attr.to_csv('PD_trial_attr_all.csv', index=False)

# summary
conn = sqlite3.connect(':memory:')
trial_attr.to_sql('trial_attr', conn, index=False, if_exists='replace')
pd.read_sql("""
    select attribute_id, ie_flag
    , count(distinct trial_id)
    from trial_attr
    group by attribute_id, ie_flag
    """, conn).to_csv('qc_trial_attr_all.csv')
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

## next tables in ct_nlp_pd
* trial_entity: trial_index, semantic+entity; CUI, assertion; trial_id, subset, section
* trial_relation: trial_index, semantic+entity, from_type+from_value; relation_type
    * trial_entity_w_relation
* entity_mappedd_by_self: semantic+entity, attr_rx
* entity_mapped_by_relation: semantic+entity, relation_type, from_type+from_value; attr_rx
    * entity_mapped_union
* attributes_all: attribute_id, attribute_group, attribute_name, attribute_value
    * entity_mapped_: semantic+entity, relation_type, from_type+from_value, attribute_id
    * trial_attribute: trial_id, attribute_id, section(inc/exc), subset (new/common)
```sh
load_into_db_schema_some_csvs.py rimsdw ct_nlp_pd PD_trial_entity_20200514.csv
load_into_db_schema_some_csvs.py rimsdw ct_nlp_pd PD_trial_relation_20200514.csv
load_into_db_schema_some_csvs.py rimsdw ct_nlp_pd entity_mapped_by_relation_20200515.csv
load_into_db_schema_some_csvs.py rimsdw ct_nlp_pd entity_mapped_by_self_20200515.csv -d
load_into_db_schema_some_csvs.py rimsdw ct_nlp_pd PD_attribute_coded_20200515.csv
```
```sql
set search_path=ct_nlp_pd;
create or replace view trial_entity_w_relation as
select e.*
, nvl(relation_type, '_') relation_type
, nvl(from_type, '_') from_type
, nvl(from_value, '_') from_value
from pd_trial_entity_20200514 e
left join pd_trial_relation_20200514 r using (trial_index, semantic, entity)
;

drop view entity_mapped_union;
create or replace view entity_mapped_union as
select semantic, entity
, relation_type, from_type, from_value
, rtrim(attr_rex_raw, '|') attr_rex
from entity_mapped_by_relation_20200515
union
select semantic, entity
, '_', '_', '_'
, rtrim(attr_rex_raw, '|') attr_rex
from entity_mapped_by_self_20200515;

drop table entity_mapped_attr cascade;
create table entity_mapped_attr as
select e.*, attribute_id
from entity_mapped_union e
join pd_attribute_coded_20200515 on ct.py_contains(attribute_id, attr_rex)
;

create or replace view v_trial_attribute as
select distinct trial_id
, subset, ie_flag as section
, attribute_id
from trial_entity_w_relation t
join entity_mapped_attr using (semantic, entity, relation_type, from_type, from_value)
order by trial_id, section desc, attribute_id
;
-- qc
select * from v_trial_attribute;
select count(*), count(distinct trial_id), count(distinct attribute_id) from v_trial_attribute;
select count(*), count(distinct attribute_id) from entity_mapped_attr;
create view qc_trial_attr_all as
    select attribute_id, section
    , count(distinct trial_id) trials
    from v_trial_attribute
    group by attribute_id, section
    order by attribute_id, section
;
```
* deliver
```sh
select_from_db_schema_table.py rimsdw ct_nlp_pd v_trial_attribute > v_trial_attribute_20200515.csv
select_from_db_schema_table.py rimsdw ct_nlp_pd qc_trial_attr_all > qc_trial_attribute_20200515.csv
load_into_db_schema_some_csvs.py pdesign db_data_bridge v_trial_attribute_20200515.csv qc_trial_attribute_20200515.csv
```

