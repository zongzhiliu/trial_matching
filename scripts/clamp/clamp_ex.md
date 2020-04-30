# the excise to parse criteria using clamp
## round 1
* cat result files with the file prefix as trial_index column
```bash
head -n1 NCT02221739-New-IC.txt | gsed 's/^/trial_index\t/' | gsed 's/Start/iStart/;s/End/iEnd/' > res.tsv
for f in *.txt; do a=${f%%-*.txt}; cat $f | gsed '1d' | gsed "s/^/$a\t/" >>res.tsv; done
mv res.tsv nsclc.tsv
```
* debug
```ipython
import sqlite3
df = pd.read_csv('nsclc.tsv', delimiter='\t', encoding='latin1')
conn = sqlite3.connect(':memory:')
df.to_sql('df', conn, index=False, if_exists='replace')

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

