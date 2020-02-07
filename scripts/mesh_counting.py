import pandas as pd
from deprecation import deprecated

def get_branch_size(nodes):
  """return the branch size starting from the first node.
  """
  self = nodes[0]
  for i, node in enumerate(nodes):
    if not node.startswith(self):
      return i
  return i+1

@deprecated(details='using get_size_and_total instead')
def each_total(df):
  """yield the total of branch values starting from each node(row).
  """
  for istart, row in df.iterrows():
    size = get_branch_size(df[istart:]['tree_number'].values)
    yield df[istart:istart+size]['pc'].sum()

def main_old():
    # add a column 'total' of self and descendants
    df = pd.read_csv('Top50trial_mesh_pc.csv')
    df = df.sort_values(by='tree_number').reset_index()
    df['total'] = list(each_total(df))
    df.to_csv('Top50trial_mesh_pc_branch_total.csv', index=False)



def _each_size(nodes):
    """yield the number of nodes of the branch starting with each node."""
    for i, node in enumerate(nodes):
        yield get_branch_size(nodes[i:])

def _each_total(pc, sizes):
    """yield sum of node values (pc) of each branch."""
    for i, (count, size) in enumerate(zip(pc, sizes)):
        yield pc[i:i+size].sum()

def get_size_and_total(df):
    """return size (number of nodes) and total (sum of node values) of each branch (row).

    df: a data frame with tree_number and pc, it will be sorted using tree_number.
        tree_number: the node name, need to be the same number of characters at the same level
        pc: the value (patient count) for each node.
    """
    size = list(_each_size(df['tree_number'].values))
    total = list(_each_total(df['pc'].values, size))
    return size, total

## supporting json tree presentation
def new_node(name, parent=None, children=None):
    return dict(name=name, parent=parent,
        children=(children if children else []))

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

def main_d3_tree(incsv, outjs):
    #tree data json file
    #incsv = 'out.test_mesh_counting.csv'
    #outjs = open('out.treeData.js', 'w')
    if isinstance(outjs, str):
        outjs = open(outjs, 'w')

    df = pd.read_csv(incsv, index_col=0)
    # initate all the nodes
    nodes = {}
    nodes['root'] = new_node('root')
    for i, row in df.iterrows():
        nodes[row['tree_number']] = new_node(
            name=f"""{row['tree_number']}: {row['branch_total']}""")

    # add the parent-children
    for key, node in nodes.items():
        if key == 'root':
            continue
        parent = find_parent(key, nodes)
        parent['children'].append(node)
        node['parent'] = parent['name']

    import json
    for key, node in nodes.items():
        if not node['children']:
            del node['children']

    outjs.write('treeData = ')
    json.dump([nodes['root']], outjs)

def main(incsv, outcsv):
    #breakpoint()
    df = pd.read_csv(incsv, index_col=0)
    df = df.sort_values(by='tree_number')
    size, total = get_size_and_total(df)
    df['branch_size'] = size
    df['branch_total'] = total
    df.to_csv(outcsv)


if __name__ == '__main__':
    import sys
    main(sys.stdin, sys.stdout)


