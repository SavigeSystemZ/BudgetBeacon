# Tool Memory Redirection Protocol

Project-local memory is authoritative for project-specific agent work.

## Rules

- Use `_system/tool-memory/` as canonical per-tool memory surfaces.
- Global or home-level memory stores are pointers, not authority.
- Do not write global tool memory without explicit operator approval.

