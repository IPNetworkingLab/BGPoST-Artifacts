with open('renater.ntf', 'r') as fd:
     data = fd.read()

ids = []
for (head, tail, _, _) in [line.split(' ') for line in data.splitlines()]:
    if head not in ids: ids.append(head)
    if tail not in ids: ids.append(tail)

for idx, nid in enumerate(ids): print(idx, nid)
