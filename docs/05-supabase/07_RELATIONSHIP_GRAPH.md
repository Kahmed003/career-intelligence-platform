Career OS — Relationship Graph

Document ID: COS-SUP-REL-001Version: 1.0.0Status: Approved for implementationCanonical path: docs/05-supabase/07_RELATIONSHIP_GRAPH.mdRelated migration: supabase/migrations/20260721000500_create_relationship_graph.sql

The Relationship Graph stores typed connections between first-class Career OS objects.

It introduces:

public.relationship_types

public.object_relationships

directed and undirected semantics

endpoint validation

duplicate prevention

provenance and confidence

temporal validity

owner-scoped Row-Level Security

Initial relationship codes:

contains

belongs_to

associated_with

supports

introduced_by

works_at

applied_to

derived_from

related_to
