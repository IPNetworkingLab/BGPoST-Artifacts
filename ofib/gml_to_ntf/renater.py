from networkx import read_graphml

"""
24 -> 22 -> 11 nodes x2 = 22
20 -> 18 -> 9 nodes x2 = 18

>>> for node, degree in g.degree():
...     if degree == 1:
...             print(node)
... 
14
21
24
25
29


"""
# https://sari.cnrs.fr/wp-content/uploads/2021/12/pages_de_renatour-20120427-v2-matin.pdf, page 9
#removed = {'16': "Vannes", '17': "Lorient", '18': "Quimper", '19': "Saint-Brieuc",  '10': "Lannion", '11': "Brest", '24': "GEANT"}
#removed_l = list(removed.keys())
removed_l = []

g = read_graphml("reduced_renater.graphml")
with open('renater.ntf', 'w') as fd:
    for edge in g.edges():
        # Remove 3 leaves to obtain 40 nodes since we can not emulate more than that
        if edge[0] in removed_l or edge[1] in removed_l: continue
        fd.write(f'{edge[0]} {edge[1]} 1 5\n')
        fd.write(f'{edge[1]} {edge[0]} 1 5\n')
        print(f"Add edge between {edge[0]} and {edge[1]}")
