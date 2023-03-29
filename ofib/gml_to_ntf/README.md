# Renater

Generate a NTF topo description for a subset of the Renater 43 nodes topology of 2010.

> http://www.topology-zoo.org/files/Renater2010.graphml

We remove 3 leaf nodes to obtain 40 nodes:
- node 21: Domtom link
- node 24: GEANT peering
- node 25: Corse link

## How to use?

```console
python -m venv env
source env/bin/activate
pip install -r requirements.txt
python generate.py
```
