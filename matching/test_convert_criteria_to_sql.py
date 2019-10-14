import pytest
import convert_criteria_to_sql as modu

class TestConverter(modu.CriterionConverter):
    config = dict(
        histology = {'A', 'B', 'C'}
    )

obj = TestConverter()
def test_convert_histology():
    assert obj.convert_histology('A') == """IN ('A')"""
    assert obj.convert_histology('A, B') == """IN ('A', 'B')"""
    assert obj.convert_histology('not(A, B)') == """NOT IN ('A', 'B')"""

def test_convert_histology_error():
    assert obj.convert_histology('(A, D)') == """IN ('A', 'D')"""

def test_convert_ecog():
    assert obj.convert_ecog('0 - 1 ') == """BETWEEN 0 and 1"""

def test_convert_age():
    assert obj.convert_age('18 - 80') == """BETWEEN 18 and 80"""
    assert obj.convert_age('>=18') == """>= 18"""

def test_convert_stage_or_status__only_stage():
    assert obj.convert_stage_or_status('VI;') == """upper(stage) ~ '^(VI)' OR 0"""
    assert obj.convert_stage_or_status('III,IV;') == r"""upper(stage) ~ '^(III|IV)' OR 0"""

def test_convert_stage_or_status__both():
    assert obj.convert_stage_or_status('III,IV; recurrent, metastatic') == r"""upper(stage) ~ '^(III|IV)' OR lower(status) IN ('recurrent', 'metastatic')"""

def test_convert_stage_or_status__only_status():
    assert obj.convert_stage_or_status(';recurrent') == r"""0 OR lower(status) IN ('recurrent')"""

def test_convert_stage_or_status__error():
    with pytest.raises(NotImplementedError) as e:
        obj.convert_stage_or_status('IB-IIIA;')

    with pytest.raises(ValueError) as e:
        obj.convert_stage_or_status('III')
