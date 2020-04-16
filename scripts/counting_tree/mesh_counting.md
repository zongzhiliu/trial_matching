# count patient to mesh items
```umls
cat MRCONSO.RRF | sed 's/|$//;s/|/        /g' >> res.tsv
load_into_db_schema_some_csvs.py rimsdw umls mrconso.tsv
cat mrconso.tsv | sed -n '1 p;/   MSH     /p' > mrconso_mesh.tsv
```

# explore patient count file
```ipython
raw = pd.read_excel('DMSDW2019_ICD_MeSH_PTCOUNT_20190201.xlsx')
df = raw[~pd.isna(raw.MeSH_Term)]
tmp = df[['ICD_Code', 'MeSH_code', 'PC']].drop_duplicates()

res = tmp.groupby(['MeSH_code']).agg(['count'])['ICD_Code']
sele = res.index[res['count']>1]
tmp[tmp.MeSH_code.isin(sele)]
```
# counting each branch
```bash
working_dir="$PWD"
script_dir='/Users/zongzhiliu/git/trial_matching/scripts/counting_tree'
python ${script_dir}/mesh_counting.py <Top50trial_mesh_pc.csv > Top50trial_mesh_pc_branch_total.csv
cd ${script_dir}
python tree_display.py < ${working_dir}/Top50trial_mesh_pc_branch_total.csv > treeData.js
open test_mesh_counting.html
```
