# ADR-0001: Use PostgreSQL First with a Graph-Compatible Domain Model

**Status:** Accepted  
**Date:** 2026-07-12

## Context

Career OS requires typed relationships, graph traversal, AI reasoning, transactional integrity, integrations, and rapid MVP development.

## Decision

Use PostgreSQL through Supabase as the primary transactional database. Represent graph semantics through first-class object tables and typed relationship records. Keep the domain and service layers graph-compatible so a dedicated graph projection can be introduced later.

## Consequences

### Benefits

- Simpler infrastructure
- Strong transactional guarantees
- Mature authorization and row-level security
- Easier Supabase integration
- Lower operational cost
- No premature graph-database dependency

### Tradeoffs

- Complex multi-hop traversal may require recursive SQL
- Graph analytics may eventually need a dedicated engine
- Relationship queries require careful indexing

## Migration Trigger

Evaluate a dedicated graph engine when real workloads show persistent problems with traversal latency, graph algorithms, semantic search, or AI context assembly.
