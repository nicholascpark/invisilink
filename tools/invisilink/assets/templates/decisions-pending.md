# Decisions Pending

*Queued items requiring human approval. Reviewed at the start of every interactive session (Step 0.5).*
*Autonomous cycles queue non-routine decisions here. Irrevocable actions blocked by the hook land here.*

## Template
```
## Decision: {short title}
- **queued:** {timestamp}
- **queued by:** {autonomous cycle / irrevocable-gate hook / agent name}
- **type:** irrevocable | spending | strategy | pivot | other
- **context:** {what happened, why this decision is needed}
- **proposed action:** {what the agent wants to do}
- **expected outcome:** {what we expect to happen}
- **cost:** ${amount or "none"}
- **reversible:** yes | no
- **status:** pending | approved | rejected | expired
- **resolved:** {timestamp when human decides}
- **resolution:** {what was decided and why}
```
