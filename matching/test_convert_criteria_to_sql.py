import convert_criteria_to_sql as modu

config = dict(
    histology = {'A', 'B', 'C'}
)
def test_convert_histology():
    assert modu.convert_histology('A', config) == """IN ('A')"""
    assert modu.convert_histology('A, B', config) == """IN ('A', 'B')"""
    assert modu.convert_histology('not(A, B)', config) == """NOT IN ('A', 'B')"""

def test_convert_histology_error():
    assert modu.convert_histology('(A, D)', config) == """IN ('A', 'D')"""
