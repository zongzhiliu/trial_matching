# cd Sema4/Reference
* combine three versions of trade names
```ipy
import sqlite3
df = pd.read_csv('cancer_drug_alias.csv')
conn = sqlite3.connect(':memory:')
df.to_sql('df', conn, index=False, if_exists='replace')

tmp = pd.read_sql("""
    select generic_name, trade_name_dan trade_name from df union
    select generic_name, trade_name_OA trade_name from df union
    select generic_name, trade_name_sunny trade_name from df""", conn)

res = tmp[~tmp.trade_name.isna()]
res.to_csv('res.csv', index=False)
```
* edited by meng (res_v2)
* edited again
    1. Lower case all the names (keep only generic and trade/alias names)
    1. Remove duplicated records
    1. If two or more ‘generic name’ refer to the same drug, keep only one of them (the shorter one) as generic, and move the others to the trade/alias column  
        Ex: ado-trastuzumab, ado-trastuzumab emtansine, trastuzumab emtansine

* load to redshift d
```bash
load_into_db_schema_some_csvs.py viecure ct ref_drug_alias_v3.csv
```
