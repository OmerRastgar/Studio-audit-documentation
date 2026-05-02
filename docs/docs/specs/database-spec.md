# Database Infrastructure Constraints

This spec describes the shared Prisma and database expectations that every feature touching persistent storage must honor.

## 1. Prisma Client Usage

- **Singleton pattern**: Import `prisma` from `backend/src/lib/prisma.ts` only. That module manages a single `PrismaClient` attached to `globalThis` in non-prod environments, preventing connection storms during hot reloads or lambda-style invocations.
- **Avoid re-instantiation**: Do not call `new PrismaClient()` elsewhere. If a test or script needs a different Prisma instance, isolate it in a dedicated setup file and clean it up afterwards.
- **Logging scope**: By default, Prisma logs `['error', 'warn']`. Feature code should not enable query logging globally; add per-operation `log` overrides only when debugging a specific issue, and remove them before checking in.

## 2. Connection Resilience

- **Env and pooling**: The deployed services rely on `DATABASE_URL` to carry both the host credentials and connection tuning parameters. Embed options such as `?connection_limit=20&pool_timeout=20` in the URL when provisioning databases instead of hardcoding them in code.
- **Bootstrap check**: Call `testConnection()` from `backend/src/lib/prisma.ts` during startup health probes or CI smoke tests to ensure the database is reachable. Capture failures in the service logs (`logger.error`) so infrastructure alerting can trigger.
- **Transactions & retries**: Use `prisma.$transaction` for multi-step updates that must succeed atomically. Surface Prisma Errors to the caller so service layers can decide whether to retry, and log enough context to diagnose deadlocks/timeouts.
- **Read-replica awareness**: If a route needs strongly consistent reads after writes (e.g., role changes, permission grants), force the query to the primary node via intents or use immediate transaction scopes rather than relying on eventual replication.

## 3. Schema & Migration Hygiene

- **Schema updates**: A feature that touches DB schema must update the Prisma schema file and run `npx prisma migrate dev` locally. Commit both the schema and migration files.
- **Migration strategy**: Deployments should run `npx prisma migrate deploy` instead of `db push` with `--accept-data-loss`. Document this constraint in deployment scripts and avoid destructive flags in prod manifests.
- **Seed data alignment**: Whenever new roles or default entities are introduced, ensure seed scripts (demo, admin, etc.) and Kratos sync scripts populate matching records so new features have a fully provisioned environment.

## References

- `backend/src/lib/prisma.ts`
- `backend/src/lib/types.ts`
- `backend/src/routes/auth.ts`
- `gateway/opa/policies/rbac.rego`
