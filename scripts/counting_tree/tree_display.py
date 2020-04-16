import sys, json
from itertools import islice
import pandas as pd

## supporting json tree presentation
def new_node(name):
    """contruct a tree node with a dict.
    """
    return dict(name=name,
        parent=None, children=list())

def each_ancestor(key):
    pair = key.rsplit('.', 1)
    while len(pair)==2:
        yield pair[0]
        pair = pair[0].rsplit('.', 1)
    yield 'root'

def find_parent(key, nodes):
    for k in each_ancestor(key):
        if k in nodes:
            return nodes[k]

def main(incsv, outjs):
    """Output a js file with treeData.

    - incsv: a csv file with [tree_number, branch_total, ...]
    - outjs: a writable stream
    """
    df = pd.read_csv(incsv, index_col=0)

    # initate all the nodes
    nodes = dict(root = new_node('root'))
    for i, row in df.iterrows():
        nodes[row['tree_number']] = new_node(
            name=f"""{row['tree_number']}: {row['branch_total']}""")

    # add the parent-children
    for key, node in islice(nodes.items(), 1, None): #skip the root
        parent = find_parent(key, nodes)
        parent['children'].append(node)
        node['parent'] = parent['name']

    # write to the js file
    for key, node in nodes.items():
        if not node['children']:
            del node['children']
    outjs.write('treeData = ')
    json.dump([nodes['root']], outjs)

if __name__ == '__main__':
    if len(sys.argv) != 1:
        sys.exit(f"""Usage: python {sys.argv[0]} < in.csv > out.js
            , then open test_mesh_counting.html.
            \nDescription: """ + main.__doc__)
    else:
        main(sys.stdin, sys.stdout)
