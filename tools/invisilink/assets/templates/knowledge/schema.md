# Schema: Parent Generalized Knowledge Vault

*Editorial and operational rules for the parent vault. This file is the parent's `CLAUDE.md` analog — what makes the LLM librarian a disciplined wiki maintainer rather than a generic chatbot. Read this before any read or write to the vault.*

---

## Vault Identity

- **role:** parent
- **schema_version:** 1.0.0
- **scope:** generalized cross-venture meta-knowledge only
- **lineage:** Adapted from "LLM Wiki: Persistent Knowledge Base Pattern" (Karpathy gist, April 2026, `gist.github.com/karpathy/442a6bf555914893e9891c11519de94f`). Federated parent/child extensions, lineage records, packet protocol, container model, URI resolution, and capability gates are local additions, not canonical.

If `schema_version` here does not match `schema_version` in `config.json`, the librarian must refuse to operate and surface the mismatch.

## Container vs Vault

The parent knowledge lives in a **container** that holds the vault plus four peer directories:

```
{container_uri}/
├── parent/        ← the vault (this schema.md lives here, at {vault_uri}/schema.md)
├── inbox/         ← external ingress (manual drops, non-umbilical sources)
├── archives/      ← snapshots and schema migration history
├── exports/       ← egress (reports, serialized outputs)
└── meta/          ← vault-level metadata (capabilities.json, devices.json, sync-state.json)
```

The vault (`parent/`) holds compiled knowledge. The container peers hold facilities that serve the vault but are not themselves knowledge:

- **`inbox/`** — classified and promoted to `parent/raw/{subdir}/` by the librarian. Items sitting in `inbox/` are NOT yet part of the knowledge graph.
- **`archives/`** — the librarian never reads from `archives/` during normal operation.
- **`exports/`** — nothing in `exports/` is consumed by the librarian. It exists only for outputs leaving the vault.
- **`meta/capabilities.json`** — feature gate. Agents check capabilities before using optional features. READ by every agent on startup.
- **`meta/devices.json`** — device registry. Updated by the librarian whenever a new `device_id` appears in an operation.
- **`meta/sync-state.json`** — last successful sync timestamp per device. Updated by the librarian on every successful run.

Pre-migration, the container and vault are the same directory (`./knowledge/`). Post-Phase-7 migration, they diverge. Agents always read `{container_uri}/meta/...` and `{vault_uri}/...` — the URI resolution handles the difference.

## Storage and URI Resolution

All paths in this schema are LOGICAL tokens (`{vault_uri}`, `{container_uri}`). The actual filesystem location is resolved through `.claude/knowledge-config.json` in the parent control-plane repo, via the path-resolution helper at `tools/invisilink/assets/scripts/knowledge-paths.sh`.

URIs today support only the `file://` scheme. Other schemes (`s3://`, `sqlite://`) are reserved for future storage backends and will be added to the helper as new drivers when needed. Agent code never touches raw filesystem paths directly — it always goes through the helper.

### Capability check before feature use

Before using any optional feature (hybrid search, packet federation, device-tagged logging, idempotent migration), the librarian MUST check `{container_uri}/meta/capabilities.json` via the helper's `capability` subcommand:

```bash
knowledge-paths.sh capability device_tagged_logging
# exit 0 if enabled, exit 1 if not
```

If the capability is not enabled, the librarian either falls back to a simpler behavior or errors with a clear "capability not enabled" message. It does NOT silently attempt the feature and fail obscurely.

### Fallback resilience

If `vault_uri` fails to resolve (iCloud mid-sync, network outage for a future network-backed URI, dehydrated placeholder timeout), the helper falls back to `fallback_uri` for READS only. Writes during fallback are deferred and replayed when the primary URI recovers. The librarian emits a "operating in fallback mode" warning when this happens.

---

## What Belongs Here

The parent vault stores ONLY:

- **Cross-venture patterns** — generalizable execution patterns derived from venture evidence
- **Meta-instructional learnings** — insights that should change how future ventures are designed, evaluated, or extracted
- **Reusable frameworks** — parent-level evaluative frameworks (disqualifiers, enhancers, barrier-to-entry, etc.)
- **Generalized domain knowledge** — domain insights stripped of venture-specific operational detail
- **Generalized market signals** — signals worth keeping at the meta level, not just at the per-venture level
- **Filed-back query outputs** — high-value answers from agent queries that should compound
- **Lineage records** — provenance proving where each generalized abstraction came from

The parent vault NEVER stores:

- Venture-specific operational notes, experiments, or playbooks
- Domain-specific data that belongs to a single venture
- Live mirrors of child vault state
- Customer lists, partner contacts, or other venture-local artifacts
- Anything that would identify a specific venture's competitive position

If a piece of knowledge could be useful to a venture in a completely different domain, it belongs here. If it only matters within one venture, it stays in that venture's local vault.

---

## Layer Definitions

### `raw/`

Immutable ingest layer. The librarian reads from `raw/` but never modifies files. After processing, a raw file moves to `raw/{subdir}/processed/` — never deleted.

Subdirectories:

- `raw/parent/` — Forager observations and other parent control plane outputs
- `raw/ventures/{venture}/` — venture evidence packets received from child outboxes
- `raw/imports/` — manual additions, external research dumps, anything not produced by the spiral

Each subdirectory has its own `processed/` directory for archived inputs.

### `wiki/`

Compiled knowledge layer. The librarian owns this entirely. Pages are organized by type:

- `wiki/patterns/` — cross-venture patterns (the highest-value page type)
- `wiki/frameworks/` — parent-level evaluative frameworks
- `wiki/domains/` — generalized domain knowledge
- `wiki/signals/` — generalized market signals
- `wiki/queries/` — high-value query outputs filed back

A page may live in only one type subdirectory. If it could plausibly belong to two, the librarian picks the more general type and adds backlinks from the more specific page.

### `lineage/`

Provenance records. Every parent pattern page that derives from venture evidence MUST have a corresponding lineage record here. Format: `LIN-{YYYY-MM-DD}-{NNN}.md`.

Lineage records are not wiki pages — they do not appear in `index.md` and they are not queried during normal retrieval. They exist solely to make generalized knowledge auditable back to its evidence.

### Navigation files (in the vault, `{vault_uri}/`)

- `index.md` — content-oriented catalog (every page has an entry)
- `log.md` — chronological append-only event log, device-tagged
- `hot.md` — fast cache for recent state
- `config.json` — machine-readable storage and protocol settings
- `schema.md` — this file
- `lint-report.md` — most recent librarian lint output
- `health.json` — most recent librarian health snapshot

### Container-level files (in the container, `{container_uri}/`)

- `meta/capabilities.json` — feature gate (read by every agent on startup)
- `meta/devices.json` — device registry
- `meta/sync-state.json` — last successful sync timestamp per device
- `inbox/README.md` — describes how to drop manual ingestions
- `exports/.gitkeep` — placeholder; populated by export operations
- `archives/` — snapshots and migration history; not read during normal operation

---

## Page Types

Ten types are defined. Each has a default subdirectory and a confidence vocabulary.

| Type | Subdirectory | Confidence vocabulary | What it captures |
|------|--------------|----------------------|------------------|
| `pattern` | `wiki/patterns/` | lineage | Cross-venture execution patterns |
| `framework` | `wiki/frameworks/` | wiki | Parent-level evaluative frameworks |
| `domain` | `wiki/domains/` | wiki | Generalized domain knowledge |
| `market` | `wiki/domains/` | wiki | Generalized market characteristics |
| `signal` | `wiki/signals/` | wiki | Generalized market or competitive signals |
| `venture` | `wiki/queries/` | wiki | Parent-level summary of a venture (NOT venture internals) |
| `experiment` | `wiki/queries/` | wiki | Generalized experiment design notes |
| `competitor` | `wiki/signals/` | wiki | Generalized incumbent behavior insights |
| `customer` | `wiki/domains/` | wiki | Generalized customer behavior insights |
| `regulation` | `wiki/domains/` | wiki | Generalized regulatory/policy insights |

Page types `pattern` MUST use the lineage confidence vocabulary because the page's confidence is a function of cross-venture evidence count. All other types use the wiki confidence vocabulary. Mixing the two on a single page is a lint violation.

---

## Frontmatter Schema

Every wiki page has this frontmatter block. All fields are required unless marked optional.

```yaml
---
id: {type}-{domain}-{slug}
type: pattern | framework | domain | market | signal | venture | experiment | competitor | customer | regulation
tags: [tag1, tag2]
related: ["[[other-page-id]]"]
sources: [REF-001, REF-002]   # observation IDs, packet IDs, or URLs
created: YYYY-MM-DD
updated: YYYY-MM-DD
confidence: <see vocabulary section>
venture: parent
origin_scope: generalized      # always "generalized" for parent vault pages
lineage_id: LIN-2026-04-13-001 # REQUIRED for type:pattern, optional otherwise
---
```

### Field rules

- **`id`** — must match the filename without `.md` extension. Pattern: `{type}-{domain-or-area}-{slug}`. Lowercase, hyphenated, no spaces. Example: `pattern-licensed-gatekeeper-critical-path`.
- **`type`** — must be one of the ten enumerated types. No freeform values.
- **`tags`** — 2-6 tags, lowercase, hyphenated. Tags emerge organically; do not enforce a tag taxonomy.
- **`related`** — list of `[[wikilinks]]` to other pages in this vault. Every page must have at least one entry. A page with empty `related` is an orphan and fails lint.
- **`sources`** — list of observation IDs (`OBS-CN-NN`), packet IDs (`EV-VENTURE-DATE-NNN`, `DS-DATE-OBS-ID`), or URLs. Never a venture outbox file path directly — pattern pages cite lineage records, which cite outbox files.
- **`created`** — ISO date the page first existed.
- **`updated`** — ISO date the page was last meaningfully edited (not a timestamp bump).
- **`confidence`** — see Confidence Vocabulary below.
- **`venture`** — always `parent` for pages in this vault. This field exists for forward compatibility with a future unified query layer that spans parent and child vaults.
- **`origin_scope`** — always `generalized` for parent vault pages. Reserved for future cases where the same schema might be reused for non-generalized stores.
- **`lineage_id`** — REQUIRED for pages with `type: pattern`. Points to the lineage record in `lineage/` that proves the pattern's derivation. Omit this field for non-pattern types.

---

## Confidence Vocabulary

Two vocabularies, applied by page type:

### Wiki page confidence (all types except pattern)

- **`high`** — verified by multiple independent sources, recently updated, no known contradictions
- **`moderate`** — single source or moderately stale, no known contradictions
- **`low`** — speculative, stale, or contradicted but kept for context
- **`from-blueprint`** — taken from a venture blueprint without independent verification

### Pattern lineage confidence (type: pattern only)

- **`single-venture-observation`** — derived from one venture's evidence
- **`cross-venture-pattern`** — corroborated across 2+ ventures
- **`battle-tested`** — corroborated across 3+ ventures AND at least one venture acted on it

A pattern page using a wiki confidence value is a lint violation. A non-pattern page using a lineage confidence value is also a lint violation. The librarian must validate this at write time.

---

## Linkage Rules

1. **Every page must have at least one outbound `[[wikilink]]`** in its `related` field. A page that links nowhere is an orphan and fails lint.
2. **Backlinks must be bidirectional.** When page A links to page B, page B must also link to page A. The librarian is responsible for maintaining bidirectionality after each write.
3. **Pattern pages must link to their lineage record by ID** (e.g., `lineage_id: LIN-2026-04-13-001`), but they must NOT include `[[lineage/LIN-2026-04-13-001]]` in `related` because lineage records are not wiki pages.
4. **No links to child vault contents.** A parent page must never contain `[[ventures/{venture-name}/...]]` links. Cross-vault references go through lineage records or packet IDs, never direct paths.
5. **Tag co-occurrence is not a link.** Two pages sharing a tag are not automatically related; they must be explicitly linked.

---

## Query Workflow

The standard query order for any agent reading this vault:

1. Read `hot.md` — the fast cache
2. Read `index.md` — find candidate pages
3. Read 1-3 relevant wiki pages (drill in)
4. Read lineage records ONLY when querying provenance
5. Read raw evidence ONLY for verification or contradiction resolution

Do NOT skip ahead to raw evidence. Do NOT bypass the index. The discipline is what makes the wiki the canonical retrieval layer instead of decorative scaffolding.

### Filing-back rule

If a query produces ANY of:

- An answer that took reading 3+ wiki pages or 2+ raw sources to derive
- A reconciliation between two contradictory pages
- A new framework or design principle
- A comparison between two or more existing pages
- The same query asked twice within a 30-day window
- An answer that would change a meta-instruction proposal

...then the answer MUST be filed back into:

- A new wiki page (under appropriate type), OR
- An update to an existing wiki page, OR
- A `wiki/queries/` page if the answer is query-specific but reusable

AND the action must be logged in `log.md` with operation type `filed_back_query`.

The agent producing the answer is responsible for filing it back. The librarian's role is to accept the filing, integrate links, and lint for quality.

---

## Log Entry Formats

`log.md` is append-only. Every entry has this format:

```markdown
## YYYY-MM-DDTHH:MM:SSZ — {operation_type}

- **device:** {device_id from bootstrap config}
- **operation:** ingest | filed_back_query | lint_pass | contradiction_resolution | parent_learning_export | venture_evidence_import | pattern_promotion | schema_migration | inbox_promotion | fallback_mode_entered | fallback_mode_exited
- **affected_pages:** [page-id-1, page-id-2]
- **affected_lineage:** [LIN-id-1]   # if applicable
- **packet_refs:** [EV-id, PL-id]    # if applicable
- **summary:** {one-line description}
- **details:** {optional multi-line context}
```

**`device:` is REQUIRED.** It identifies which physical machine wrote the entry. If the bootstrap config has no `device_id` set, the librarian refuses to write and surfaces a clear error rather than attributing operations anonymously. Device attribution is foundational for multi-device iCloud-synced vaults — without it, sync races and concurrent writes become undebuggable.

Operation types:

- **`ingest`** — a raw file in `{vault_uri}/raw/` was processed into one or more wiki pages
- **`inbox_promotion`** — a file from `{container_uri}/inbox/` was promoted into `{vault_uri}/raw/` for processing
- **`filed_back_query`** — an agent query was filed back into the wiki
- **`lint_pass`** — the librarian ran its lint checks; details include the lint summary
- **`contradiction_resolution`** — a contradiction surfaced by lint was resolved by human or agent
- **`parent_learning_export`** — a `parent_learning` packet was sent to one or more children
- **`venture_evidence_import`** — a `venture_evidence` packet was received from a child
- **`pattern_promotion`** — a pattern's confidence was upgraded (e.g., single-venture → cross-venture)
- **`schema_migration`** — a schema version bump was applied
- **`fallback_mode_entered`** — the helper could not resolve `vault_uri` and fell back to `fallback_uri`
- **`fallback_mode_exited`** — primary URI resolution recovered; deferred writes are being replayed

Entries are written in chronological order. Do not edit past entries; only append. The librarian uses the path-resolution helper's `append` subcommand to ensure atomic writes.

### Device registry update

After writing each log entry, the librarian updates `{container_uri}/meta/devices.json` with this device's `last_seen` timestamp. If the device has not appeared before, it is added with a `first_seen` timestamp equal to the current time.

---

## Lineage Requirements

Every parent pattern page derived from venture evidence MUST have a corresponding lineage record. The pattern page references the lineage record by ID (`lineage_id` frontmatter field). The pattern page does NOT directly cite venture outbox files in its `sources` field — it cites the lineage record, and the lineage record cites the outbox files.

### Lineage record format

```markdown
---
id: LIN-2026-04-13-001
type: lineage
origin_ventures: [appealengine]
source_packets: [EV-APPEALENGINE-2026-03-26-001, EV-APPEALENGINE-2026-03-26-002]
derived_pages: ["[[pattern-licensed-gatekeeper-critical-path]]"]
created: 2026-04-13
confidentiality: generalized-from-venture-evidence
sanitization_notes: "State-specific facts removed. Specific incumbent names removed."
---

# Lineage: licensed gatekeeper critical path

## Source Evidence
- Venture: AppealEngine
- Source packets: EV-APPEALENGINE-2026-03-26-001, EV-APPEALENGINE-2026-03-26-002
- Local outbox file references (within source venture): cycle-008.md, capability-unlock-2026-03-19-attorney-outreach.md

## Abstraction Rationale
Why this venture-specific finding generalizes to other ventures. What was domain-specific and was removed. What was structural and was kept.

## Sanitization Notes
What identifying or domain-specific details were stripped before the abstraction landed in the parent pattern page.

## Derived Pages
- `[[pattern-licensed-gatekeeper-critical-path]]`
```

### Lineage rule

**No parent pattern page may cite a venture outbox file directly without an intermediate lineage record.** This keeps the parent KG clean, generalized, and auditable. The librarian rejects any pattern page write that violates this rule.

---

## Linting Rules

The librarian runs the following checks periodically (default cadence: every 5 cycles, configurable in `config.json`).

### Universal lint checks

1. **Orphan pages** — pages with no inbound `related` references
2. **Broken links** — `[[wikilinks]]` that resolve to non-existent pages
3. **Stale pages** — pages not updated in 3+ cycles, surfaced for review
4. **Contradictions** — pages whose claims contradict `thesis.md` or each other
5. **Schema violations** — pages missing required frontmatter, using wrong vocabulary, or violating field rules
6. **Confidence-type mismatch** — pattern pages using wiki confidence, or non-pattern pages using lineage confidence

### Parent-vault-specific lint checks

7. **Pattern pages missing lineage** — any `type: pattern` page without a `lineage_id` field, or whose `lineage_id` points to a non-existent lineage record
8. **Lineage records pointing to retired pages** — lineage records whose `derived_pages` references no longer exist
9. **Child-specific detail in parent pages** — heuristic check for venture names, customer names, or domain-specific facts that should have been generalized away
10. **Direct child vault references** — any link of the form `[[ventures/...]]` or any path containing the child vault root
11. **Conflicted iCloud copies** — files matching `* (conflicted copy*).md` (iCloud sync race artifacts)
12. **Vault size budget** — total vault size exceeding 75% of the configured budget

The librarian writes findings to `lint-report.md` (overwritten each run). The librarian only flags; it does not auto-fix contradictions, gaps, or stale pages. Resolution is the human's or another agent's job.

---

## Ingestion Rules

Two ingestion surfaces exist: `{container_uri}/inbox/` (container-level) and `{vault_uri}/raw/` (vault-level).

**Step 0: Promote from `inbox/` to `raw/`.**

Before processing raw files, the librarian checks `{container_uri}/inbox/` for any files. These are external deposits that have not yet been classified. For each file:

1. Determine the target subdir in `{vault_uri}/raw/` based on filename and content (typically `raw/imports/` for manual drops).
2. Move the file (not copy) from `inbox/` to the target `raw/` subdir using the helper's atomic write primitive.
3. Append an `inbox_promotion` entry to `log.md` with the device tag.

After promotion, `inbox/` is empty and everything to process lives under `{vault_uri}/raw/`.

**Step 1: Identify source type** by subdirectory:

- `raw/parent/` — Forager observation, classify by content (market, signal, domain, etc.)
- `raw/ventures/{venture}/` — venture evidence packet, route to learning-curator's generalization logic before any pattern page is created
- `raw/imports/` — manual deposit (promoted from `inbox/` or deposited directly), classify by content

2. **Check for existing pages** — search `index.md` and the appropriate `wiki/{type}/` subdirectory for pages covering the same topic. Enrich an existing page rather than creating a new one when in doubt.

3. **Generalize before writing** — for venture-derived inputs, strip venture-specific names, locations, customer details, and domain-specific facts. The parent page is the abstraction, not the original.

4. **Create or update the page** — write or edit the wiki page following the schema. If creating a pattern page, ALSO create the lineage record in `lineage/`.

5. **Update bidirectional links** — for each page mentioned in `related`, add a backlink in that page's `related` field.

6. **Update `index.md`** — add or update the entry for this page under the appropriate type header. Use the index entry format (see below).

7. **Append to `log.md`** — record the ingest operation with affected pages and packet refs.

8. **Move the raw file** — `raw/{subdir}/{file}` → `raw/{subdir}/processed/{file}`. Never delete.

### Index entry format

Each entry in `index.md` is a single bullet under its type header:

```markdown
- [[pattern-licensed-gatekeeper-critical-path]] — Licensed-professional partnerships are Phase 0 fatal assumptions when revenue activation requires their participation. (battle-tested, 3 ventures, updated 2026-04-13)
```

Format rules:

- One bullet per page
- Page ID as a wikilink (no path prefix — librarian resolves to actual file)
- Em-dash separator
- One-sentence summary, never more than 200 characters
- Parenthetical metadata: `(confidence, evidence-count-if-applicable, updated date)`

Within each type group, entries are sorted by `updated` date descending (most recent first).

---

## Contradiction Handling

When the librarian's lint detects a contradiction between two pages, or between a page and `thesis.md`:

1. **Surface, do not resolve.** Write the contradiction to `lint-report.md` with both citations and a one-line description of the conflict.
2. **Do not silently overwrite.** If new evidence contradicts an existing page, the librarian creates a new page or appends to the existing one with a "Contradicting Evidence" section, but does not delete the original claim.
3. **Confidence downgrade.** If the contradiction is clearly stronger than the original claim, downgrade the original page's confidence by one level (high → moderate → low). Do not delete.
4. **Human or agent resolution.** The Evolver or human reads the lint report and decides whether to update, retire, or split the conflicting pages. The librarian executes the decision but does not make it.

Contradictions are features, not failures. They are evidence the system is paying attention.

---

## Schema Migration

When `schema_version` is bumped:

1. **Patch (1.0.0 → 1.0.1)** — editorial wording change in this file. No migration needed. Update `schema_version` in this file and in `config.json`. Append a `schema_migration` entry to `log.md` with device tag.

2. **Minor (1.0.0 → 1.1.0)** — new optional fields or new page types. Existing pages remain valid; lint warns when new fields are missing. Update `schema.md`, `config.json`, and `meta/capabilities.json` (new capabilities may be added with safe defaults). Append a `schema_migration` entry. No data migration script required.

3. **Major (1.0.0 → 2.0.0)** — breaking change to required fields or vocabulary. Required:
   - Snapshot the entire container to `archives/schema-migrations/{from}-to-{to}/` BEFORE migration
   - Run the migration script at `tools/invisilink/assets/scripts/migrate-schema-{from}-to-{to}.sh`
   - Update `schema.md`, `config.json`, and `meta/capabilities.json`
   - Append `schema_migration` entry to `log.md` with the script path and device tag
   - Re-run a full lint pass after migration
   - The librarian refuses to operate until the new schema validates

### Idempotency requirement

Every migration script MUST be idempotent. Running the same migration twice produces the same end state. This is non-negotiable because iCloud sync, interrupted runs, and multi-device handoffs mean migrations often need to be re-run.

Required idempotency properties (the librarian validates any migration script it's asked to run):

1. **Content-addressable copies.** Each source file is hashed (sha256) before copying. If the destination exists AND has the same hash, the copy is skipped. If the destination exists with a different hash, the script aborts with a "destination has diverged" error rather than silently overwriting.
2. **Marker files track completion.** Each migration writes to `{archives_root}/schema-migrations/{from}-to-{to}/MIGRATION_STATE.json` with per-step completion flags. Re-runs read the marker and resume from the first incomplete step.
3. **Temp-file-then-rename for every write.** No partial writes visible to iCloud sync.
4. **Reversible until committed.** Until `MIGRATION_STATE.json` has `committed: true`, the pre-migration state is preserved in `archives/{date}-pre-migration/`.
5. **Every step logged with device tag.** Re-runs append new entries, never edit past ones.

If `meta/capabilities.json` has `"idempotent_migration": false`, the librarian refuses to run any migration script — the guarantee is foundational, and a vault that doesn't support it cannot be safely upgraded.

The librarian refuses to operate on a vault whose `schema_version` does not match what this `schema.md` declares.

---

## Operating Principles

These are what the librarian (and any agent reading this vault) should internalize:

- **Compounding requires structure.** A flat log is read once and buried. A typed, linked, indexed page is findable forever.
- **Generalize ruthlessly.** A venture fact is not a learning. A pattern that would change how you'd build a different venture in a different market is a learning.
- **Backlinks are the product.** A page with no inbound or outbound links is dead weight. The wiki's value is in its connections, not its pages.
- **Lineage is mandatory for patterns.** A pattern without a lineage record is a claim without evidence.
- **The index is canonical.** If a page is not in `index.md`, the librarian considers it nonexistent.
- **Raw is sacred.** Never edit raw files. Never delete raw files. Move them to `processed/` after handling.
- **Lint, don't fix.** Surface problems. Let humans and other agents resolve them.
- **The schema is the contract.** Frontmatter discipline now means painless migration when the storage layer changes.
- **Filing-back is non-optional.** If you compute a reusable answer, file it. Otherwise the next query rediscovers it from scratch — which is exactly what this architecture exists to prevent.
