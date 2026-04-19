# Invisilink Changelog

## v1.5 — 2026-04-18

- Removed bogus `command:` field from `flash.md` frontmatter and from stub templates in `incubator-scaffold.md` and `gnosis.md` (Claude Code ignores this field — `name` is the canonical identifier)
- Simplified v1.2 retrofit (step 17) — forward-only, no longer mentions or renames legacy `deploy-team/` directories. Any remaining legacy dirs are a one-time manual cleanup
- Trigger: manual (skill frontmatter audit after directory/name mismatch in appealengine)

## v1.4 — 2026-04-07

- Rewrote `flash.md` Step 5 as pure meta-instruction with asset references — all scripts and templates moved to `tools/invisilink/assets/`, skill file reduced from ~1340 lines to ~940
- Updated upgrade mode references throughout
- Trigger: manual (skill-size reduction, separation of instruction from artifact)

## v1.3 — 2026-04-07

- Added federated knowledge base infrastructure — `knowledge/` directory with `index.md`, `hot.md`, `raw/`, `wiki/` now deployed to every venture
- Added `knowledge-librarian` worker under Founder (processes raw findings into typed wiki pages, maintains index, runs linting)
- Added knowledge-compounding principle to DNA.md
- Added Step 5m (knowledge base infrastructure) and knowledge-graph symlink step (retrofit step 18) for parent–venture Obsidian graph federation (symlink federation later retired in favor of typed packets; see incubator-scaffold Step 7c)
- Trigger: manual (knowledge base rollout)

## v1.2 — 2026-03-28

- Renamed system from deploy-team to Invisilink
- Skill command renamed from `/deploy-team` to `/flash`
- Added `/gnosis` skill — establishes umbilical connection to parent for pre-existing repos
- Added `/bless` skill — parent-side delivery of `/gnosis` to pre-existing repos
- Added `download.md` backward-compatibility shim redirecting to `/flash`
- Linked ventures now pull upgrades directly from parent filesystem (no GitHub round-trip)
- Added v1.2 retrofit step to upgrade mode (writes `umbilical/config.md` + flash stub for existing incubator-spawned ventures)
- Gnosis registers directly in parent's ventures.md (no approval hook needed — parent already blessed)
- Trigger: manual (Invisilink rename + gnosis/bless implementation)

## v1.1 — 2026-03-27

- Expanded umbilical-monitor skill template with explicit signal type routing
- Added `parent_learning` signal type (medium priority, from parent's venture-learnings curation)
- Added `infrastructure_upgrade_available` signal type (low priority, invisilink version notifications)
- Added `assumption_challenge`, `market_intelligence`, `directive` signal types with routing rules
- Trigger: manual (federated learning system implementation)

## v1.0 — 2026-03-26

- Initial import from `nicholascpark/invisilink` GitHub repo
- Source of truth moved to parent repo (`tools/invisilink/flash.md`)
- GitHub repo becomes distribution mirror
- Trigger: manual (initial setup)
