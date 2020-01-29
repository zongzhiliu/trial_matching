# the excise to parse criteria using clamp
## round 1
* cat result files with the file prefix as trial_index column
```bash
head -n1 191582.txt | gsed 's/^/trial_index\t/' | gsed 's/Start/iStart/;s/End/iEnd/' > res.tsv
for f in *.txt; do a=${f%.txt}; cat $f | gsed '1d' | gsed "s/^/$a\t/" >>res.tsv; done
mv res.tsv round1_ec.tsv
```
* load to redshift d
```bash
psql -c 'create schema clamp_ct'
load_into_db_schema_some_csvs.py rdmsdw clamp_ct round1_ec.tsv -d
```
* count frequencies
```sql
set search_path=clamp_ct
;
\set prefix round1_ec;
create view v_round1_ec_entity_summary as
select semantic, entity
, count(*) records, count (distinct trial_index) trials
from round1_ec
group by semantic, entity
order by trials desc, records desc
;

create view v_round1_ec_semantic_summary as
select semantic
, count(distinct entity) entities
, count(*) records, count (distinct trial_index) trials
from round1_ec
group by semantic
order by trials desc, records desc, entities desc
;
```
* report as csv
```
select_from_db_schema_table.py rdmsdw clamp_ct.v_round1_ec_entity_summary > v_round1_ec_entity_summary.csv
select_from_db_schema_table.py rdmsdw clamp_ct.v_round1_ec_semantic_summary > v_round1_ec_semantic_summary.csv
```

