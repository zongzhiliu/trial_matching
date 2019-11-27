raw = pd.read_csv('PCA_attribue_trial.csv', skiprows=1, index_col=0)
# seperate inc/exc
sele = raw.columns.str.endswith('.1')
inc = raw[raw.columns[~sele]]
exc = raw[raw.columns[sele]]
exc.columns =  exc.columns.str.replace('.1', '')

# unstack and combine inc/exc
res = pd.DataFrame(dict(inclusion=inc.unstack(), exclusion=exc.unstack()))
res.index.names = ['trial_id', 'attribute_id']
res.to_csv('res.csv')

############################################################## 
# old
# convert into vertical seperately
_inc = inc.unstack().reset_index()
_exc = exc.unstack().reset_index()
# inc.unstack().to_csv('_inc.csv', header=False) #['trial_id', 'attribute_id', 'inclusion'])
# exc.unstack().to_csv('_exc.csv', header=False) #['trial_id', 'attribute_id', 'inclusion'])
# _inc = pd.read_csv('_inc.csv', header=None)
# _exc = pd.read_csv('_exc.csv', header=None)
_inc.columns=['trial_id', 'attribute_id', 'inclusion']
_exc.columns=['trial_id', 'attribute_id', 'exclusion']

# combine and export to a csv
res = _inc
res['exclusion'] = _exc['exclusion']
res.to_csv('trial_attribute.csv', index=False)
res.head()
