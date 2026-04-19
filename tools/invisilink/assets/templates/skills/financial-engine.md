---
name: financial-engine
version: 1.0
model: haiku
description: Processes data/inbox cost records into sustenance.json, recalibrates projections.
triggers:
  - schedule: "every 1h"
  - event: "new-transaction-in-inbox"
---

# Financial Engine

Read `data/inbox/` for new cost event files. For each: classify the transaction, update `sustenance.json` model statistics, refresh projections. Check if balance is below funding threshold (20% of last investment) — if so, write a funding request to `data/outbox/funding-request.json`. Log your own execution cost. Write results as JSON to stdout.
