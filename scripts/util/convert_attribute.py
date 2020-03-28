import pandas as pd, sqlite3

def _parse_trial_attribute(raw_csv):
    raw = pd.read_csv(raw_csv, skiprows=2, index_col=0)
    # seperate inc/exc
    sele_inc = raw.columns.str.strip().str.contains('^NCT\d+$')
    sele_exc = raw.columns.str.strip().str.contains('^NCT\d+\.1$')
    assert sum(sele_inc) == sum(sele_exc)
    inc = raw.loc[:,sele_inc]
    exc = raw.loc[:,sele_exc]
    exc.columns = exc.columns.str.replace('.1', '', regex=False)
    assert all(exc.columns == inc.columns)
    return raw, inc, exc

def _unpivot_i_e_m_l(raw_csv):
    """convert the pivot format of raw to vertical one.
    - raw_cswv: (inclusion, must, logic, exclusion) for each trial
        with trial_id on inclusion and exclusion column
    """
    raw, inc, exc = _parse_trial_attribute(raw_csv)

    sele_must = raw.columns.str.strip().str.startswith('M')
    sele_logic = raw.columns.str.strip().str.startswith('l')
    must = raw.loc[:,sele_must]
    logic = raw.loc[:,sele_logic]
    must.columns = logic.columns = inc.columns #the trial_ids
    res = pd.DataFrame(dict(inclusion=inc.unstack(), exclusion=exc.unstack(),
        ie_mandatory=must.unstack(), ie_logic=logic.unstack()))
    return res

def _unpivot_i_e_m(raw_csv):
    raw, inc, exc = _parse_trial_attribute(raw_csv)
    sele_must = raw.columns.str.strip().str.startswith('M')
    must = raw.loc[:,sele_must]
    must.columns = inc.columns
    return pd.DataFrame(dict(inclusion=inc.unstack(), exclusion=exc.unstack(), 
        ie_mandatory=must.unstack()))

def _unpivot_i_e(raw_csv):
    raw, inc, exc = _parse_trial_attribute(raw_csv)
    return pd.DataFrame(dict(inclusion=inc.unstack(), exclusion=exc.unstack()))

def _check_and_filter_trial_attribute(res):
    # check
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

def convert_trial_attribute_plus_m_l(raw_csv):
    """convert the pivot format to vertical one

    - raw_csv: (inclusion, must, exclusion) for each trial
    """
    res = _unpivot_i_e_m_l(raw_csv)
    result = _check_and_filter_trial_attribute(res)
    return result

def convert_trial_attribute_plus_m(raw_csv):
    """convert the pivot format to vertical one

    - raw_csv: (inclusion, must, exclusion) for each trial
    """
    res = _unpivot_i_e_m(raw_csv)
    return _check_and_filter_trial_attribute(res)


def convert_trial_attribute(raw_csv):
    """convert the pivot format to vertical one

    - raw_csv: (inclusion, exclusion) for each trial
    """
    res = _unpivot_i_e(raw_csv)
    return _check_and_filter_trial_attribute(res)

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
    # filter for implemented
    mask = pd.isna(df['code_type']) | (df['code_type']=='-')
    df = df[~mask]

    # attribute_manditated as bool: later
    # code transformation: to be improved later
    df['code'] = df['code_raw']
    sele = df['code_type'].isin(
        ['icd_rex', 'icd_rex_other', 'icd_le_tempo', 'icd_earliest', 'proc_icd_rex'])
    # convert icd10 and icd9 into full python regx
    df.loc[sele, 'code'] = [f"^({'|'.join((x,) if pd.isna(y) else (x,y)).replace('.', '[.]')})"
            for i, (x, y) in df[['code_raw', 'code_ext']][sele].iterrows() ]

    # convert gene name(s) to regx
    sele = df['code_type'].isin(['gene_variant', 'gene_vtype', 'gene_rtype'])
    df.loc[sele, 'code'] = [ f"^({x})$"
            for x in df['code_raw'][sele] ]

    # use lowercase drug names
    sele = df['code_type'].isin(['drug_name'])
    df.loc[sele, 'code'] = [ x.lower()
            for x in df['code_raw'][sele] ]

    # add border to drug_moa_rex: later
    sele = df['code_type'].isin(['drug_moa_rex'])
    #df.loc[sele, 'code'] = [ x.replace('(', '[(]').replace(')', '[)]')
    #        for x in df['code_raw'][sele] ]
        #do not convert the parathesis, as real rex parathesis might be used

    return df

def summarize_crit_attribute(df):
    print(df.logic.value_counts())
    print(df.code_type.value_counts())
    print(df.attribute_value.value_counts())
    #print(df.attribute_value_norm.value_counts())
    print(df.code_raw.describe())
    print(df.code_ext.describe())
    print(df.code.describe())


