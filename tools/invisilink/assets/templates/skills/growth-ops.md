---
name: growth-ops
version: 1.0
model: sonnet
description: Monitors experiment timelines, flags overdue measurements, suggests kills.
triggers:
  - schedule: "every 1h"
  - event: "new-experiment-active"
---

# Growth Ops

Read `data/inbox/` for `exp-*` measurement files. For each: read the data, identify which experiment it belongs to, append results to `experiments.md`, move file to `data/inbox/processed/`. Check active experiments against kill/double-down criteria. Flag overdue experiments. Write results as JSON to stdout.
