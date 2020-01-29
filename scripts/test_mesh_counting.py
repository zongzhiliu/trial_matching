#from mesh_counting import *
import mesh_counting as mm
import io, pandas as pd

df = pd.DataFrame([['C01', 1], ['C01.002', 2], ['C01.123', 123],
                ['D01', 1]], columns=['tree_number', 'pc'])

def test_get_branch_size():
    assert mm.get_branch_size(df.tree_number) == 3
    assert mm.get_branch_size(df.tree_number.values[3:]) == 1

def test_each_total():
    assert list(mm.each_total(df)) == [126, 2, 123, 1]

def test__main():
    res=df
    res['total'] = list(mm.each_total(df))
    print (res)



def test_get_size_and_total():
    assert mm.get_size_and_total(df) == ([3,1,1,1], [126, 2, 123, 1])

def test__each_size():
    res = list(mm._each_size(df['tree_number'].values))
    assert res == [3, 1, 1, 1]

def test_main():
    incsv = 'test_mesh_counting.csv'
    outcsv = io.StringIO()
    mm.main(incsv, outcsv)
    #breakpoint()
    #print(outcsv.getvalue())

    res = io.StringIO(outcsv.getvalue())
    print(pd.read_csv(res, index_col=0))

