import pandas as pd, sqlite3

def convert_trial_attribute_plus_m(raw_csv):
    """convert the pivot format to vertical one

    - raw_csv: (inclusion, must, exclusion) for each trial
    """
    raw = pd.read_csv(raw_csv, skiprows=2, index_col=0)
    # seperate inc/exc
    sele_inc = raw.columns.str.strip().str.contains('^NCT\d+$')
    sele_exc = raw.columns.str.strip().str.contains('^NCT\d+\.1$')
    sele_must = raw.columns.str.strip().str.startswith('M')
    assert sum(sele_inc) == sum(sele_exc) == sum(sele_must)
    inc = raw.loc[:,sele_inc]
    exc = raw.loc[:,sele_exc]
    must = raw.loc[:,sele_must]
    exc.columns = must.columns = inc.columns

    # unstack and combine inc/exc
    res = pd.DataFrame(dict(inclusion=inc.unstack(), exclusion=exc.unstack(), ie_mandatory=must.unstack()))
    res.index.names = ['trial_id', 'attribute_id']
    res.reset_index(inplace=True)
    res['inclusion'] = res.inclusion.str.strip().str.replace('x10^', 'e', regex=False)
    res['exclusion'] = res.exclusion.str.strip().str.replace('x10^', 'e', regex=False)

    # check
    check = ~res.inclusion.isna() & ~res.exclusion.isna()
    assert not any(check) #sum(check)

    #filter
    sele = ~res.inclusion.isna() | ~res.exclusion.isna()
    return res[sele]

def convert_trial_attribute(raw_csv):
    """convert the pivot format to vertical one

    - raw_csv: (inclusion, exclusion) for each trial
    """
    raw = pd.read_csv(raw_csv, skiprows=2, index_col=0)
    # seperate inc/exc
    sele = raw.columns.str.endswith('.1')
    inc = raw[raw.columns[~sele]]
    exc = raw[raw.columns[sele]]
    exc.columns =  exc.columns.str.replace('.1', '', regex=False)
    assert all(inc.columns==exc.columns)

    # unstack and combine inc/exc
    res = pd.DataFrame(dict(inclusion=inc.unstack(), exclusion=exc.unstack()))
    res.index.names = ['trial_id', 'attribute_id']
    res.reset_index(inplace=True)
    res['inclusion'] = res.inclusion.str.strip()
    res['inclusion'] = res.inclusion.str.replace('x10^', 'e', regex=False)
    res['exclusion'] = res.exclusion.str.strip()
    res['exclusion'] = res.exclusion.str.replace('x10^', 'e', regex=False)

    # check
    check = ~res.inclusion.isna() & ~res.exclusion.isna()
    assert not any(check) #sum(check)

    #filter
    sele = ~res.inclusion.isna() | ~res.exclusion.isna()
    return res[sele]

def unique_non_null(s):
    return s.dropna().unique()

def summarize_ie_value(res):
    print(f'trial_id value:\n{res.trial_id.value_counts().describe()}')
    print(f'attribute_id value:\n{res.attribute_id.value_counts().describe()}')
    print(f'ie value:\n{pd.concat((res.inclusion, res.exclusion)).value_counts(dropna=False)}')
    # con = sqlite3.connect(':memory:')
    return res.fillna('').groupby('attribute_id').agg(dict(inclusion=['unique'], exclusion=['unique']))

def convert_crit_attribute(raw_csv):
    df = pd.read_csv(raw_csv)
    assert max(df.attribute_id.value_counts()) == 1 #no dup
    df = df[~pd.isna(df['code_type'])]
    df['code'] = df['code_raw']
    sele = df['code_type'].isin(['icd_rex', 'icd_rex_other']) #str.startswith('icd_rex')
    # convert icd10 and icd9 into full python regx
    df.loc[sele, 'code'] = [f"^({'|'.join((x,) if pd.isna(y) else (x,y)).replace('.', '[.]')})"
            for i, (x, y) in df[['code_raw', 'code_ext']][sele].iterrows() ]

    sele = df['code_type'].isin(['alteration_rex'])
    df.loc[sele, 'code'] = [ f"^({x})$"
            for x in df['code_raw'][sele] ]

    sele = df['code_type'].isin(['drug_name'])
    df.loc[sele, 'code'] = [ x.lower()
            for x in df['code_raw'][sele] ]
    return df

def summarize_crit_attribute(df):
    print(df.logic.value_counts())
    print(df.code_type.value_counts())
    print(df.attribute_value.value_counts())
    print(df.attribute_value_norm.value_counts())
    print(df.code_raw.describe())
    print(df.code_ext.describe())
    print(df.code.describe())


