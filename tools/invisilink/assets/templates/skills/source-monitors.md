---
name: source-monitors
version: 1.0
model: haiku
description: Tracks data sources for changes relevant to venture assumptions.
triggers:
  - schedule: "every 12h"
---

# Source Monitors

Check all configured data sources for changes since last cycle. Compare current state to last known state. Evaluate changes against `assumptions.md`. Write change alerts to `data/inbox/`. Write results as JSON to stdout.
