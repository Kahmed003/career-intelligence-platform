## 1. Purpose

Defines the minimum test standard for the Career OS Supabase backend.

A schema is not production-ready merely because its migration executes.

## 2. Test Layers

Career OS requires:

1. migration/reset tests;
2. schema and constraint tests;
3. trigger/function tests;
4. Row-Level Security tests;
5. Storage policy tests;
6. Edge Function tests;
7. repository/service integration tests;
8. end-to-end workflow tests.

## 3. Migration Tests

CI must verify that an empty local database can be rebuilt entirely from committed migrations.

The migration sequence must fail on:

- dependency errors;
- invalid SQL;
- incompatible view definitions;
- missing object types;
- broken functions or triggers.

## 4. Constraint Tests

For each domain, test both valid and invalid states.

Examples:

- invalid lifecycle transitions;
- wrong canonical object type;
- cross-owner foreign keys;
- malformed URLs/currencies/country codes;
- invalid date ordering;
- out-of-range scores/priorities;
- duplicate identifiers.

## 5. RLS Matrix

Every user-accessible table/view requires at minimum:

| Scenario | Expected |
|---|---|
| Owner SELECT | Allow |
| Owner INSERT | Allow when valid |
| Owner UPDATE | Allow when valid |
| Owner DELETE | Per domain policy |
| Other user SELECT | Deny |
| Other user INSERT using victim owner | Deny |
| Other user UPDATE | Deny |
| Other user DELETE | Deny |
| Anonymous access | Deny unless explicitly public |

Views using `security_invoker = true` must be tested under multiple users.

## 6. Storage Tests

Test:

- owner upload;
- owner read;
- owner update/delete;
- cross-user denial;
- path-prefix enforcement;
- MIME restrictions;
- size restrictions;
- public avatar reads;
- anonymous mutation denial.

## 7. Security-Definer Functions

Tests must verify:

- correct authorization;
- hardened search path;
- no privilege escalation;
- revoked unintended EXECUTE privileges;
- same-owner enforcement;
- behavior for deleted objects.

## 8. Regression Tests

Every production bug in a migration, function, policy, or view should produce a regression test before or alongside its forward-fix migration.

## 9. Known Required Regression Coverage

The current Career OS schema should explicitly test:

- expanded Object Registry type compatibility for all introduced first-class domains;
- owner-scoped uniqueness for project codes and organization domains;
- task parent/project ownership and cycle prevention;
- opportunity matching industry lookup through Organization;
- notes full-text-search behavior;
- document primary attachment uniqueness;
- interaction organization/opportunity consistency;
- calendar synchronization uniqueness;
- campaign analytics view execution.

## 10. Test Data

Fixtures must use synthetic users and records.

At least two users are required for meaningful RLS tests.

## 11. CI Gate

A database change may merge only when:

- local reset succeeds;
- SQL tests pass;
- RLS suite passes;
- Storage tests pass when affected;
- generated types are current;
- application integration tests pass for affected slices.

## 12. Production Smoke Tests

After deployment verify:

- authentication;
- owner-scoped reads;
- representative writes;
- key derived views;
- Storage access;
- Edge Function health;
- no unexpected anonymous access.
