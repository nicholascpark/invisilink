# Vault Log

*Append-only chronological event log for this vault. Every ingest, inbox promotion, filed-back query, lint pass, contradiction resolution, packet exchange, schema migration, and fallback mode transition is recorded here. Every entry is device-tagged for multi-device attribution. Operations are sorted in chronological order. Never edit past entries; only append.*

> See `schema.md` for the full operation type catalog and entry format. Every entry follows the same structure for machine parsability. Device attribution is foundational — an entry without a `device:` field is invalid and the librarian refuses to write it.

---

<!-- Append new entries below this line. Format:

## YYYY-MM-DDTHH:MM:SSZ — {operation_type}

- **device:** {device_id from bootstrap config — REQUIRED}
- **operation:** ingest | inbox_promotion | filed_back_query | lint_pass | contradiction_resolution | parent_learning_export | venture_evidence_import | pattern_promotion | schema_migration | fallback_mode_entered | fallback_mode_exited
- **affected_pages:** [page-id-1, page-id-2]
- **affected_lineage:** [LIN-id-1]
- **packet_refs:** [EV-id, PL-id]
- **summary:** {one-line description}
- **details:** {optional multi-line context}

Example:

## 2026-04-13T20:30:00Z — ingest

- **device:** nicholas-mbp-m3
- **operation:** ingest
- **affected_pages:** [pattern-licensed-gatekeeper-critical-path]
- **affected_lineage:** [LIN-2026-04-13-001]
- **packet_refs:** [EV-APPEALENGINE-2026-03-26-001]
- **summary:** Generalized AppealEngine licensed-professional bottleneck into a cross-venture pattern.

-->
