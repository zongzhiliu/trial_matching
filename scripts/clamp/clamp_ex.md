# the excise to parse criteria using clamp

## round 1
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
* debug
```ipython
import sqlite3
df = pd.read_csv('res.tsv', delimiter='\t', encoding='latin1')
conn = sqlite3.connect(':memory:')
df.to_sql('df', conn, index=False, if_exists='replace')
```
* PD_trials
```
cd /Users/zongzhiliu/Sema4/rimsdw/ct_nlp_pd/
trial_entity = pd.read_csv('PD_trial_entity_20200507.csv')
entity = pd.read_csv('PD_entity_raw_20200507.csv')
mapped_entity = entity[entity.attribute_id.notnull()]
trial_attr = trial_entity.merge(mapped_entity, on=['Semantic', 'Entity'])[['trial_id', 'subset', 'ie_flag', 'attribute_id']]
conn = sqlite3.connect(':memory:')
trial_attr.to_csv('PD_trial_attr_gene_alteration.csv', index=False)
trial_attr.to_sql('trial_attr', conn, index=False, if_exists='replace')
# summary
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
* summary
```ipython
pd.read_sql("""
    select semantic, entity
    , count(*) records, count (distinct trial_index) trials
    from df
    group by semantic, entity
    order by trials desc, records desc
    """, conn).to_csv('nsclc_entity_summary.csv', index=False)

pd.read_sql("""
    select semantic, count(distinct entity) entities
    , count(*) records, count (distinct trial_index) trials
    from df
    group by semantic
    order by trials desc, records desc, entities desc
    """, conn).to_csv('round3_semantic_summary.csv', index=False)

conn.create_function('regexp', 2, lambda x, y:
        1 if re.search(x,y) else 0)

pd.read_sql("""
    -- select * from df where entity like '%grou%'
    select * from df where entity regexp '(?i)grou'
    """, conn)
```
* load to redshift d
```bash
#psql -c 'create schema clamp_ct'
load_into_db_schema_some_csvs.py rdmsdw clamp_ct round3_latin1.tsv -d --encoding=latin1
```
* count frequencies
```sql
set search_path=clamp_ct
;
create view v_round3_entity_summary as
select semantic, entity
, count(*) records, count (distinct trial_index) trials
from round3
group by semantic, entity
order by trials desc, records desc
;

create view v_round3_semantic_summary as
select semantic
, count(distinct entity) entities
, count(*) records, count (distinct trial_index) trials
from round3
group by semantic
order by trials desc, records desc, entities desc
;
```
* report as csv
```
select_from_db_schema_table.py rdmsdw clamp_ct.v_round1_ec_entity_summary > v_round1_ec_entity_summary.csv
select_from_db_schema_table.py rdmsdw clamp_ct.v_round1_ec_semantic_summary > v_round1_ec_semantic_summary.csv
```

