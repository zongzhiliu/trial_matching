# count patient to mesh items
```umls
cat MRCONSO.RRF | sed 's/|$//;s/|/        /g' >> res.tsv
load_into_db_schema_some_csvs.py rimsdw umls mrconso.tsv
cat mrconso.tsv | sed -n '1 p;/   MSH     /p' > mrconso_mesh.tsv
```
