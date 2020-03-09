import pandas as pd

def convert_trial_attribute(raw_csv):
    """convert the pivot format to vertical one
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

def summarize_ie_value(res):
    print(f'trial_id value:\n{res.trial_id.value_counts().describe()}')
    print(f'attribute_id value:\n{res.attribute_id.value_counts().describe()}')
    print(f'ie value:\n{pd.concat((res.inclusion, res.exclusion)).value_counts(dropna=False)}')


def convert_crit_attribute(raw_csv):
    df = pd.read_csv(raw_csv)
    assert max(df.attribute_id.value_counts()) == 1 #no dup
    df['code'] = df['code_raw']
    sele = df['code_type'] == 'icd_rex'
    df['code'][sele] = [f"^({'|'.join((x,) if pd.isna(y) else (x,y)).replace('.', '[.]')})"
            for i, (x, y) in df[['code_raw', 'code_ext']][sele].iterrows() ]
    return df

def summarize_crit_attribute(df):
    print(df.logic.value_counts())
    print(df.code_type.value_counts())
    print(df.attribute_value.value_counts())
    print(df.attribute_value_norm.value_counts())
    print(df.code_raw.describe())
    print(df.code_ext.describe())
    print(df.code.describe())


