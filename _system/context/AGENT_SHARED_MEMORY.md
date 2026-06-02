# Agent Shared Memory

Use this file for durable, cross-agent project execution memory that must remain
visible across tool boundaries.

## Purpose

- Keep active project memory in-repo so any agent can resume without relying on
  tool-local caches.
- Store durable execution truth that multiple agents should not re-derive.
- Preserve a single review surface for operator audit and correction.

## What belongs here

- locked scope and boundary decisions for the current project
- current validation baseline and known required gates
- load-bearing implementation primitives and invariants for active work
- active escalation constraints and non-negotiable safety rules

## What does not belong here

- transient scratch notes already captured in a single session
- secrets, credentials, or machine-local tokens
- raw vendor/tool cache exports
- maintainer-only template design notes from source repos

## Tool-local memory rule

Tool-local memory stores (for example `~/.claude/projects/.../memory/` or other
agent-local caches) must be treated as pointers into this repo-local file rather
than a separate source of truth.

## Entry format

- Date:
- Decision or memory:
- Why it matters:
- Revisit trigger:
