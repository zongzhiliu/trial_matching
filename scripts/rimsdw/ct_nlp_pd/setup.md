## setup the schema
```sql
create schema ct_nlp_pd;
ALTER DEFAULT PRIVILEGES IN SCHEMA ct_nlp_pd GRANT ALL on tables to mingwei_zhang;
```

## Compile the entities from NLP
* cat entity result files with the file prefix as trial_index column
* cat relationship files with the file prefix as trial_index column
```bash
export working_dir='/Users/zongzhiliu/Sema4/rimsdw/ct_nlp_pd/'
export entity_dir='/Users/zongzhiliu/Sema4/Clamp/MM Clamp Processed - R1/entity'
export relation_dir='/Users/zongzhiliu/Sema4/Clamp/MM Clamp Processed - R1/relation'

#cd '/Users/zongzhiliu/Downloads/Split NCT-IE Clamp Results'
cd "$entity_dir"
first_file=$(ls | head -n1)
head -n1 "$first_file" | gsed 's/^/trial_index\t/' | gsed 's/Start/iStart/;s/End/iEnd/' > res.tsv
for f in *.txt; do
    a=${f%%.txt};
    cat $f | gsed '1d' | gsed "s/^/$a\t/" >>res.tsv; 
done
#cd '/Users/zongzhiliu/Downloads/Clinical Trial R1 Relations'
cd "$relation_dir"
first_file=$(ls | head -n1)
head -n1 "$first_file" | gsed 's/^/trial_index\t/' > res.tsv
for f in *.txt; do
    a=${f%%-relation.txt};
    cat $f | gsed '1d' | gsed "s/^/$a\t/" >>res.tsv; 
done
cd "$working_dir"
```

* extract trial_id, subset, inc/exc from file name
```ipython
entity_dir=os.environ['entity_dir']
relation_dir=os.environ['relation_dir']
df = pd.read_csv(f'{entity_dir}/res.tsv', delimiter='\t')
#, encoding='latin1')
    # error: UnicodeDecodeError: 'utf-8' codec can't decode byte 0xd7 in position 6: invalid continuation byte
csv_reader = csv.reader(open(entity_dir+'/res.tsv'), delimiter='\t')
for i, row in enumerate(csv_reader):
    print (i, row)
for i, line in enumerate(io.open(f'{entity_dir}/NCT01775553-New-IC.txt', 'rb')): print (i, line)
tmp = open(f'{entity_dir}/NCT01775553-New-IC.txt', 'rb').read()
tmp[1248:1268].decode()
tmp[1238:1268].decode(errors='ignore')
tmp[1238:1268].decode(errors='replace')
tmp[1238:1268].decode(errors='backslashreplace')
tmp[1238:1268].decode(errors='xmlcharrefreplace')
ignore
tmp


df['trial_id'] = [x.split('-')[0] for x in df.trial_index]
df['subset'] = [x.split('-')[1] for x in df.trial_index]
tmp = [x.split('-')[-1] for x in df.trial_index]
df['ie_flag'] = ['IC-EC' if x not in ('EC', 'IC') else x for x in tmp]
df.to_csv('PD_trial_entity_20200514.csv' , index=False)

df = pd.read_csv('relation_raw.tsv', delimiter='\t') #, encoding='latin1')
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
* entity_mappedd_by_self: semantic+entity, attr_rex
* entity_mapped_by_relation: semantic+entity, relation_type, from_type+from_value; attr_rex
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

create or replace view _trial_attribute_strict as
select distinct trial_id
, subset, ie_flag as section
, attribute_id
from trial_entity_w_relation t
join entity_mapped_attr using (semantic, entity, relation_type, from_type, from_value)
order by trial_id, section desc, attribute_id
;
```
* rescue the entities not mapped to any attributes because of an additional relation.
```sql
-- find candicate entity occurences to be rescued:
create or replace view _e_candidate as
with rel_and_nom as (
    select distinct trial_index, semantic, entity, trial_id, subset, ie_flag
    from trial_entity_w_relation
    left join entity_mapped_union using (semantic, entity, relation_type, from_type, from_value)
    where attr_rex is null and relation_type != '_'
), e_mapped as ( -- exclude those already mapped with anothe relation (value + tempo)
    select distinct trial_index, semantic, entity, trial_id, subset, ie_flag
    from trial_entity_w_relation
    join entity_mapped_union using (semantic, entity, relation_type, from_type, from_value)
    where attr_rex is not null
)
select * from rel_and_nom except
select * from e_mapped
;

-- rescure using blank relation
create view _trial_attribute_rescue as
select distinct trial_id, subset, ie_flag as section
, attribute_id
from (select trial_id, subset, ie_flag
	, semantic, entity
	, '_' as relation_type, '_' as from_type, '_' as from_value
    from _e_candidate)
join entity_mapped_attr using (semantic, entity, relation_type, from_type, from_value)
order by trial_id, section desc, attribute_id
;

create view v_trial_attribute as
select * from _trial_attribute_strict union
select * from _trial_attribute_rescue
order by trial_id, section desc, attribute_id
;
-- qc
select * from v_trial_attribute;
select count(*), count(distinct trial_id), count(distinct attribute_id) from v_trial_attribute;
    -- 11762   | 811     | 228
create view qc_trial_attribute as
    select attribute_id, section
    , count(distinct trial_id) trials
    from v_trial_attribute
    group by attribute_id, section
    order by attribute_id, section
;
select * from qc_trial_attribute;
* deliver
```sh
select_from_db_schema_table.py rimsdw ct_nlp_pd v_trial_attribute > v_trial_attribute_20200515.csv
select_from_db_schema_table.py rimsdw ct_nlp_pd qc_trial_attribute > qc_trial_attribute_20200515.csv
load_into_db_schema_some_csvs.py pdesign db_data_bridge v_trial_attribute_20200515.csv qc_trial_attribute_20200515.csv
```

