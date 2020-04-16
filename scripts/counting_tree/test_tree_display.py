import tree_display as mm
import io, pandas as pd, subprocess as sp

incsv = 'test_s3_tree.csv'
outjs = 'treeData.js'
template_html = 'test_mesh_counting.html'

def test_each_ancestor():
    assert list(mm.each_ancestor('a.b.c')) == ['a.b', 'a', 'root']

def test_main():
    with open('treeData.js', 'w') as outjs:
        mm.main(incsv, outjs)
    # sp.call(f'open {template_html}', shell=True)

def test_script():
    sp.call(f'python tree_display.py < {incsv} > {outjs}', shell=True)
    # sp.call(f'open {template_html}', shell=True)


