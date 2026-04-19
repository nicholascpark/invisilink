# Experiments

*Parallel experiment swarm. Maintain 3-5 active experiments at all times.*

## Active Experiments

### Template (copy for each new experiment)
```
### EXP-{NNN}: {name}
- **hypothesis:** {if we do X, then Y will happen}
- **curriculum question:** {which program.md question this answers}
- **metric:** {machine-verifiable outcome}
- **threshold:** {success = above this, fail = below this}
- **timeline:** {start date → end date}
- **cost cap:** ${amount}
- **channel:** {where this experiment runs}
- **capability required:** {which capability from capabilities.md}
- **status:** draft | running | measuring | decided
- **baseline:** {state before experiment}
- **result:** {measured outcome}
- **decision:** keep | kill | pivot
- **learning:** {what we now know that we didn't before}
- **injected to:** {what next experiment uses this learning}
```

## Loop Summary

*Updated after each autoresearch cycle. What patterns are emerging across experiments?*

| Cycle | Date | Experiments Reviewed | Keeps | Kills | Key Pattern |
|-------|------|---------------------|-------|-------|-------------|

## Completed Experiments

*Moved here after decision. Preserve full record.*
