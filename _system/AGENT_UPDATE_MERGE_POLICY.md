# Agent Update Merge Policy

## Context
When `bootstrap/update-template.sh` is executed with `--refresh-managed` and it detects drift between a locally modified template-managed file and the upstream template, it will NOT silently overwrite the file. 

Instead, it injects explicit conflict markers into the file, preserving both the `HEAD (Project Tailored)` content and the `TEMPLATE (New Features)` content.

## Agent Directives
1. **Never Revert to Blindly Overwriting**: You must respect the project-specific tailoring. Do not delete the user's/project's modifications to force conformity with the template unless the modifications are outright broken or violate core security constraints.
2. **Merge-Only Resolution**: Your task when encountering a file with `<<<<<<< HEAD` markers is to intelligently merge the logic. Add the new features and structures from the `TEMPLATE` section while surgically retaining the context, logic, and configurations from the `HEAD` section.
3. **Format Integrity**: Be aware that injecting conflict markers into JSON, YAML, or strict schema files will temporarily invalidate their syntax. It is your responsibility to parse the two blocks, unify the data logically, and restore structural integrity.
4. **Logical Separation**: Remember that this template is a versatile, multi-agent environment. A downstream app will have different runtime needs than the meta-system template itself. Retain downstream project definitions.
