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
