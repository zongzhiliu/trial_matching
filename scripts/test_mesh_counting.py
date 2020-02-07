#from mesh_counting import *
import mesh_counting as mm
import io, pandas as pd, subprocess as sp

df = pd.DataFrame([['C01', 1], ['C01.002', 2], ['C01.123', 123],
                ['D01', 1]], columns=['tree_number', 'pc'])
exp_size = [3,1,1,1]
exp_total = [126, 2, 123, 1]

def test_get_branch_size():
    assert mm.get_branch_size(df.tree_number) == 3
    assert mm.get_branch_size(df.tree_number.values[3:]) == 1

def test_each_total():
    assert list(mm.each_total(df)) == exp_total

def test_each_ancestor():
    assert list(mm.each_ancestor('a.b.c')) == ['a.b', 'a', 'root']

def test_main_d3_tree():
    incsv = 'out.test_mesh_counting.csv'
    with open('treeData.js', 'w') as outjs:
        mm.main_d3_tree(incsv, outjs)
    sp.call('open test_mesh_counting.html', shell=True)

def test__main():
    res=df
    res['total'] = list(mm.each_total(df))
    print (res)


def test_get_size_and_total():
    assert mm.get_size_and_total(df) == (exp_size, exp_total)

def test__each_size():
    res = list(mm._each_size(df['tree_number'].values))
    assert res == exp_size

def test__each_total():
    res = list(mm._each_total(df['pc'].values, exp_size))
    assert res == exp_total

def test_main():
    incsv = 'test_mesh_counting.csv'
    outcsv = io.StringIO()
    mm.main(incsv, outcsv)
    #breakpoint()
    #print(outcsv.getvalue())

    res = io.StringIO(outcsv.getvalue())
    res_df = pd.read_csv(res, index_col=0)
    exp_total_tail = [40703, 990, 210, 11, 6]
    assert list(res_df.tail(5).branch_total) == exp_total_tail

    '''
        C01.539.895  1         40703
            C01.703  4           990
        C01.703.080  1           210
        C01.703.980  2            11
    C01.703.980.600  1             6
    '''

def test_script():
    import subprocess as sp
    incsv = 'test_mesh_counting.csv'
    sp.call(f'python mesh_counting.py < {incsv} > out.{incsv}', shell=True)
    print(pd.read_csv(f'out.{incsv}', index_col=0))


