# Prompt Effectiveness Tracking

Protocol for measuring which prompt packs and prompt templates produce successful outcomes, per model and task type.

## Why track

Not all prompt packs work equally well across all models. A pack designed for large-context models may overwhelm a 7B local model. Tracking success/failure rates per model builds evidence for better task routing.

## What to track

Record the following in `context/prompt-usage-log.json` after each significant agent session:

| Field | Description |
|-------|-------------|
| `timestamp` | ISO 8601 UTC |
| `model` | Model family used (e.g., `claude-sonnet-4`, `gpt-4o`) |
| `prompt_pack` | Prompt pack ID (e.g., `M1_FEATURE_DELIVERY`) |
| `prompt_template` | Template used, if any (e.g., `developer_prompt_template`) |
| `task_type` | Category: feature, bugfix, review, refactor, architecture, docs, test, security |
| `outcome` | `success`, `partial`, `failure` |
| `notes` | Brief explanation of what worked or didn't |

## Schema

```json
{
  "entries": [
    {
      "timestamp": "2026-03-27T14:30:00Z",
      "model": "claude-sonnet-4",
      "prompt_pack": "M1_FEATURE_DELIVERY",
      "prompt_template": "developer_prompt_template",
      "task_type": "feature",
      "outcome": "success",
      "notes": "Clean implementation with tests on first pass"
    }
  ]
}
```

## When to record

- **Always record** when using a prompt pack for a non-trivial task.
- **Record partial** when the agent got most of the way but needed manual correction.
- **Record failure** when the output was unusable or fundamentally wrong.
- **Skip recording** for trivial tasks (formatting, typo fixes).

## How to use the data

1. **Model selection**: If a pack consistently fails with model X but succeeds with model Y, route that task type to model Y.
2. **Pack improvement**: Low success rates indicate the pack needs revision — perhaps clearer constraints or better examples.
3. **Template tuning**: If a template works for one task type but not another, consider task-specific variants.
4. **Context budget correlation**: Cross-reference with `context-budget-profiles.json` to see if failures correlate with context tier mismatches.

## Rotation

Keep the last 100 entries. Older entries can be summarized into aggregate statistics and archived.

## Aggregate reporting

Periodically summarize:

```
Model            Pack                 Success  Partial  Failure
claude-sonnet-4  M1_FEATURE_DELIVERY  12       2        1
gpt-4o           M2_DEBUG_STABILIZE   8        3        0
deepseek-v3      M10_GREENFIELD       3        1        2
```

Use this to update `AGENT_PERFORMANCE_GUIDE.md` recommendations.

## Integration

- Agents should check this log before selecting a prompt pack to see if prior evidence suggests a better choice.
- The `AGENT_PERFORMANCE_GUIDE.md` references this tracking protocol.
- Health trends (`bootstrap/report-health-trends.sh`) can incorporate prompt effectiveness signals in future iterations.
