# ADR-0003: Adopt Mission Control Plus Embedded AI Interface

**Status:** Accepted  
**Date:** 2026-07-12

## Context

Career OS must support daily execution, organization, strategic decision-making, and context-aware intelligence.

A dashboard-only interface would make AI feel secondary. An AI-first conversational interface would make routine review, tracking, and structured workflows less efficient.

## Decision

Career OS will use Mission Control as the primary visual interface and embedded AI throughout the application.

Mission Control will surface:

- Today’s priorities
- Calendar commitments
- Actionable emails
- Application deadlines
- Interview preparation
- Relationship follow-ups
- Relevant opportunities
- Career risks
- Goal progress
- Market and trading review items

AI will appear contextually within objects and workflows rather than primarily as a standalone chatbot.

A global command palette will support:

- Universal search
- Navigation
- Object creation
- Quick actions
- Context-aware AI commands

## Consequences

### Benefits

- Supports rapid daily review
- Preserves structured workflows
- Provides AI assistance without requiring repetitive prompts
- Keeps recommendations connected to current context
- Supports both visual and command-driven interaction

### Tradeoffs

- Requires consistent AI behavior across multiple modules
- Increases interface-design complexity
- Requires strong context assembly and permissions
- Mission Control must avoid becoming overcrowded

## Interface Principle

Mission Control is the cockpit.

Embedded AI is the strategic copilot.

The user retains authority over consequential decisions and external actions.
