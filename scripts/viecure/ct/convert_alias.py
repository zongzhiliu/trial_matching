import pandas as pd

IMPORT_PATH = 'drug_yun.xlsx'
EXPORT_PATH = 'drug_alias.csv'

df = pd.read_excel(IMPORT_PATH, sheet_name='Sheet1')
new_df = df.set_index(['drug_name']).apply(lambda x: x.str.split(';').explode()).reset_index()
new_df = new_df.set_index(['drug_name']).apply(lambda x: x.str.split(',').explode()).reset_index().dropna()

new_df.to_csv(EXPORT_PATH, sep=';',index=False)


