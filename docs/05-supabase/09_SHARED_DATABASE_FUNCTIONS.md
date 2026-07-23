Career OS — Shared Database Functions

Document ID: COS-SUP-FUNC-001Version: 1.0.0

This module provides reusable SQL helper functions used throughout the schema.

Functions

private.current_user_id() – returns auth.uid().

private.is_object_owner(object_id uuid) – checks ownership of an object.

private.assert_object_owner(object_id uuid) – raises if caller is not owner.

private.soft_delete_object(object_id uuid) – marks an object deleted.

private.touch_object(object_id uuid) – refreshes updated_at.

These helpers reduce duplicated authorization logic across triggers and RLS.
