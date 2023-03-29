# Route Reflector dynamic reconfiguration

```
        ┌─────────┐
     ┌──┤  GoBGP  ├──┐
     │  └─────────┘  │     AS1
 xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
   ┌─┴───┐        ┌──┴──┐  AS2
   │ RR1 ├────────┤ RR2 │
   └──┬──┘        └──┬──┘
      │    ┌─────┐   │    ┌─────┐
      └────┤ RR3 ├───┘    │ CL1 │
           └─────┴────────┴─────┘
```
