import pytest
import numpy as np
#import sys, pathlib
#sys.path.insert(0, str(pathlib.Path('..').resolve()))
import matching.convert_criteria_to_sql as modu

obj = modu.CriterionConverter(
    config = dict(
        valids = dict(
            histology = {'A', 'B', 'C'},
            stage = {'I', 'II', 'III', 'IV', 'limited', 'extensive'},
        )
    )
)

def test_prepare_cond():
    assert modu.prepare_cond('abc ##ignore') == 'abc'
    assert modu.prepare_cond('abc ') == 'abc'
    assert modu.prepare_cond('##ignore') == ''
    assert modu.prepare_cond(' ') == ''
    assert modu.prepare_cond(np.nan) is None

def test_previously_treated():
    assert obj.convert_previously_treated('') == 'NULL' #is None
    assert obj.convert_previously_treated('Null')== 'NULL' # is None
    assert obj.convert_previously_treated('no').endswith('=0')
    assert obj.convert_previously_treated('yes ##>=2').endswith('>=1')

def test_convert_histology():
    assert obj.convert_histology('A') == """IN ('A')"""
    assert obj.convert_histology('A, B') == """IN ('A', 'B')"""
    assert obj.convert_histology('not(A, B)') == """NOT IN ('A', 'B')"""

def test_convert_histology_error():
    assert obj.convert_histology('(A, D)') == """IN ('A', 'D')"""

def test_convert_ecog():
    assert obj.convert_ecog('0 - 1 ').endswith("""BETWEEN 0 and 1""")
def test_convert_age():
    assert obj.convert_age('18 - 80').endswith("""BETWEEN 18 and 80""")
    assert obj.convert_age('>=18').endswith(""">= 18""")

def test_convert_stage_or_status__only_stage():
    assert obj.convert_stage_or_status('IV').endswith(""" IN ('IV')""")
    assert obj.convert_stage_or_status('II, IIIA, IIIB').endswith("""~ '^(IIIA|IIIB)'""")
    #assert obj.convert_stage_or_status('IV;') == """stage_base IN ('IV') OR 0"""
    #assert obj.convert_stage_or_status('III,IV;') == r"""stage_base IN ('III', 'IV')' OR 0"""

def test_convert_stage_or_status__only_status():
    assert obj.convert_stage_or_status(';recurrent, metastatic').endswith(""" IN ('recurrent', 'metastatic')""")

def test_convert_stage_or_status__both():
    #assert obj.convert_stage_or_status('III,IV; recurrent, metastatic') == r"""stage ~ '^(III|IV)' OR lower(status) IN ('recurrent', 'metastatic')"""
    print( obj.convert_stage_or_status('III,IV; recurrent, metastatic') )



@pytest.mark.skip(reason='implement later')
def test_convert_stage_or_status__range():
    #assert  obj.convert_stage_or_status('IB-IIIA;') == r"""stage_full between 'IB' and 'IIIA' OR 'I' < stage_base and stage_base < 'III' OR 0"""
    print( obj.convert_stage_or_status('IB-IIIA;') == r"""stage_full between 'IB' and 'IIIA' OR 'I' < stage_base and stage_base < 'III' OR 0""" )

def test_convert_stage_or_status__error():
    with pytest.raises(ValueError) as e:
        obj.convert_stage_or_status('VI')

    with pytest.raises(ValueError) as e:
        obj.convert_stage_or_status('recurrent')

