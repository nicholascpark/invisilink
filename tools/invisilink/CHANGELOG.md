# Invisilink Changelog

## v1.2 — 2026-03-28

- Renamed system from deploy-team to Invisilink
- Skill command renamed from `/deploy-team` to `/download`
- Added `/gnosis` skill — establishes umbilical connection to parent for pre-existing repos
- Added parent-side SessionStart hook (`gnosis-check.sh`) for connection approval flow
- Linked ventures now pull upgrades directly from parent filesystem (no GitHub round-trip)
- Added v1.2 retrofit step to upgrade mode (writes `umbilical/config.md` + download stub for existing incubator-spawned ventures)
- Trigger: manual (Invisilink rename + gnosis implementation)

## v1.1 — 2026-03-27

- Expanded umbilical-monitor skill template with explicit signal type routing
- Added `parent_learning` signal type (medium priority, from parent's venture-learnings curation)
- Added `infrastructure_upgrade_available` signal type (low priority, invisilink version notifications)
- Added `assumption_challenge`, `market_intelligence`, `directive` signal types with routing rules
- Trigger: manual (federated learning system implementation)

## v1.0 — 2026-03-26

- Initial import from `nicholascpark/invisilink` GitHub repo
- Source of truth moved to parent repo (`tools/invisilink/download.md`)
- GitHub repo becomes distribution mirror
- Trigger: manual (initial setup)
