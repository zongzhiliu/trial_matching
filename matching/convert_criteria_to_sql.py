"""convert the trial-criteria matrix to sql files

aiming at disease=nsclc only
"""
import sys, warnings, textwrap
import toml, pandas as pd

def quote(x):
    return f"'{x}'"

def to_between(cond, func):
    low, high = [func(x) for x in cond.split('-')]
    return f"""BETWEEN {low} and {high}"""

# to be improved using accepted values
def is_valid_stage(x):
    return x.startswith(('0', 'I', 'II', 'III', 'IV'))

def is_base_stage(x):
    return x in {'0', 'I', 'II', 'III', 'IV'}

#later, comment_char from config
def prepare_cond(cond, comment_char='#'):
    if pd.isnull(cond):
        return None
    return cond.split(comment_char)[0].strip()

config = dict(
    valids = dict(
        histology={'small cell carcinoma', 'squamou cell carcinoma', 'carcinoid'}
        )
    )
class CriterionConverter():

    def __init__(self, config=config):
        self.config = config

    def convert_histology(self, cond):
        """make a list of included histologies

        eg: squamous cell carcinoma -> in ('squamous cell carcinoma')
        eg: not(small cell carcinoma) -> not in ('small cell carcinoma', 'carcinoid')
            later EXCLUDING: [x for x in accepted_disease_histologies if x not in (...)]
        """
        valids = self.config['valids']['histology']
        if cond.startswith('not'):
            heading = 'NOT IN'
            items_raw = cond[3:].strip(':()')
        else:
            heading = 'IN'
            items_raw = cond.strip('()')

        items = [x.strip() for x in items_raw.split(',')]
        for x in items:
            if not x in valids:
                warnings.warn(f'{x} not a valid histology: {valids}')

        items_str = ', '.join(quote(x) for x in items)
        return f"""{heading} ({items_str})"""

    def convert_ecog(self, cond):
        """make ecog to a between
        eg: 0-1 -> between 0 and 1
        """
        cond = prepare_cond(cond)
        if not cond:
            return 'NULL'

        attrname = 'ecog'
        return f'{attrname} {to_between(cond, int)}'

    def convert_age(self, cond):
        """make age to a between or >=
        """
        cond = prepare_cond(cond)
        if not cond:
            return 'NULL'

        attrname = 'age'
        if cond.startswith('>='):
            low = int(cond[2:])
            return f"""{attrname} >= {low}"""
        else: #between
            return f"""{attrname} {to_between(cond, int)}"""

    def convert_previously_treated(self, cond):
        """yes/no/null or blank
        """
        cond = prepare_cond(cond)
        if not cond or cond.lower()=='null':
            return 'NULL'
        if cond.lower()=='yes':
            cond = '>=1'
        elif cond.lower()=='no':
            cond = '=0'
        else:
            raise ValueError(f'{cond} not in {yes, no, null}!')

        return f"""max_lot {cond}"""

    def convert_stage_or_status(self, cond):
        """ stage OR status
        """
        cond = prepare_cond(cond)
        if not cond:
            return 'NULL'

        if '-' in cond:
            raise NotImplementedError('range of stage to be implemented later')

        # split into stage and status part
        if ';' not in cond:
            stage_part = cond.strip()
            status_part = ''
        else:
            stage_part, status_part = [x.strip() for x in cond.split(';')]

        sql_elems = []
        # construct stage sql
        if stage_part:
            stage_pieces = [x.strip().upper() for x in stage_part.split(',')]
            for x in stage_pieces:
                if not is_valid_stage(x):
                    raise ValueError(f'{x} is not a valid stage!')

            base_stages = [x for x in stage_pieces if is_base_stage(x)]
            if base_stages:
                base_stage_str = ','.join([quote(x) for x in base_stages])
                sql_elems.append(f"""stage_base IN ({base_stage_str})""")

            full_stages = [x for x in stage_pieces if not is_base_stage(x)]
            if full_stages:
                full_stage_str = '|'.join(full_stages)
                sql_elems.append(f"""stage ~ '^({full_stage_str})'""")

        # construct status sql
        if status_part:
            status_pieces = ', '.join(quote(x.strip().lower()) for x in status_part.split(','))
            sql_elems.append(f"""lower(status) IN ({status_pieces})""")

        return ' OR '.join(sql_elems)


def main(in_csv, config_toml='config.toml'):
    """write a sql file for each row of trial criteria
    """
    #in_csv = 'LCA_trial_matching.csv'
    ##^^^^ debug
    config = toml.load(config_toml)
    patient_schema = config['patient_schema']
    patient_attr_table = config['patient_attr_table']
    outdir = config['outdir']

    converter = CriterionConverter(config)
    df = pd.read_csv(in_csv, index_col=0)
    for i, row in df.iterrows():
        age_cond = converter.convert_age(row['Age'])
        ecog_cond = converter.convert_ecog(row['ECOG'])
        previously_treated_cond = converter.convert_previously_treated(row['previously_treated'])
        stage_cond = converter.convert_stage_or_status(row['Stage_or_status'])
        select = f"""select {i} as trial_id, person_id
            , {age_cond} as age
            , {ecog_cond} as ecog
            , {stage_cond} as stage
            , {previously_treated_cond} as previously_treated
            from {patient_schema}.{patient_attr_table}
            """
        with open(f'{outdir}/ct_{i}.sql', 'w') as ofile:
            ofile.write(select)

if __name__ == '__main__':
    main(sys.stdin)

