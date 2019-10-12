"""convert the trial-criteria matrix to sql files

aiming at disease=nsclc only
"""
import warnings

config = dict(
    histology={'small cell carcinoma', 'squamou cell carcinoma', 'carcinoid'}
)

def quote(x):
    return f"'{x}'"

def convert_histology(cond, config):
    """make a list of included histologies

    eg: squamous cell carcinoma -> in ('squamous cell carcinoma')
    eg: not(small cell carcinoma) -> not in ('small cell carcinoma', 'carcinoid')
        later EXCLUDING: [x for x in accepted_disease_histologies if x not in (...)]
    """
    valids = config['histology']
    if cond.startswith('not'):
        heading = 'NOT IN'
        items_raw = cond[3:].strip(':()')
    else:
        heading = 'IN'
        items_raw = cond.strip('()')

    items = [x.strip() for x in items_raw.split(',')]
    for x in items:
        if not x in valids:
            warnings.warn(f'{x} not in valids: {valids}')

    items_str = ', '.join(quote(x) for x in items)
    return f"""{heading} ({items_str})"""

