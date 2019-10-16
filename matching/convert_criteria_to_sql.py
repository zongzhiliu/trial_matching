"""convert the trial-criteria matrix to sql files

aiming at disease=nsclc only
"""
import warnings


def quote(x):
    return f"'{x}'"

def to_between(cond, func):
    low, high = [func(x) for x in cond.split('-')]
    return f"""BETWEEN {low} and {high}"""

def is_valid_stage(x):
    return x.startswith(('I', 'II', 'III', 'IV'))

class CriterionConverter():
    config = dict(
        histology={'small cell carcinoma', 'squamou cell carcinoma', 'carcinoid'}
        )

    def convert_histology(self, cond):
        """make a list of included histologies

        eg: squamous cell carcinoma -> in ('squamous cell carcinoma')
        eg: not(small cell carcinoma) -> not in ('small cell carcinoma', 'carcinoid')
            later EXCLUDING: [x for x in accepted_disease_histologies if x not in (...)]
        """
        valids = self.config['histology']
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
        cond = cond.strip()
        return to_between(cond, int)

    def convert_age(self, cond):
        """make age to a between or >=
        """
        cond = cond.strip()
        if cond.startswith('>='):
            low = int(cond[2:])
            return f""">= {low}"""
        else: #between
            return to_between(cond, int)

    def convert_stage_or_status(self, cond):
        """ stage OR status
        """
        cond = cond.strip()
        #if '-' in cond:
        #    raise NotImplementedError('range of stage to be implemented later')

        # split into stage and status part
        if ';' not in cond:
            stage_part = cond.strip()
            status_part = ''
        else:
            stage_part, status_part = [x.strip() for x in cond.split(';')]

        # construct stage sql
        if not stage_part:
            stage_sql = '0'
        else:
            stage_pieces = [x.strip().upper() for x in stage_part.split(',')]
            for x in stage_pieces:
                if not is_valid_stage(x):
                    raise ValueError(f'{x} is not a valid stage!')
            stage_str = '|'.join(stage_pieces)
            stage_sql = f"""upper(stage) ~ '^({stage_str})'"""

        # construct status sql
        if not status_part:
            status_sql = '0'
        else:
            status_pieces = ', '.join(quote(x.strip().lower()) for x in status_part.split(','))
            status_sql = f"""lower(status) IN ({status_pieces})"""

        return f"""{stage_sql} OR {status_sql}"""

