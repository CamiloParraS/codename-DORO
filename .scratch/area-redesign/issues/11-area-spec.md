# Area redesign spec and build-ticket rewrite

Type: task
Status: open
Blocked by: 08, 09, 10

## Question

Collapse the resolved tickets into the per-Area level-design spec (Harbour and Core space, Radio relay station, Research annex), then rewrite build tickets `ghost-layer-build/issues/25`, `26`, `30` and `31` to match. The Harbour is already built (`tools/build_harbour.gd`), so its section records the greybox as built plus the lessons from the Harbour greybox. The other two Areas reuse its generator data shape.
