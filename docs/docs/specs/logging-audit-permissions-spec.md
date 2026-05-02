# Logging, Audit, and Permission Enforcement Constraints

This spec captures how logs and audit records should be emitted plus which permission mechanisms must be used so that feature-level specs can align with the existing observability and compliance stack.

## 1. Logging Channel Expectations

- **Canonical logger**: All runtime logs must go through `backend/src/lib/logger.ts`, which configures Pino with `service: 'backend'`, the current `NODE_ENV`, and a `pino-pretty` transport for console-friendly output. Avoid ad-hoc `console.log` statements in business logic; use `logger.info`, `logger.warn`, `logger.error`, etc., and tag each entry with the service and component context.
- **Log level control**: Runtime verbosity is controlled via `LOG_LEVEL`, defaulting to `info`. When feature-level debugging is necessary, temporarily raise the level locally but revert before merging. Do not change the transport configuration, as structured metadata is required downstream.
- **Fluent Bit forwarding**: Infrastructure expects logs to flow through Fluent Bit (URL provided via `FLUENT_BIT_URL`). Ensure the environment variable is populated in deployment manifests; no code should bypass this by pushing directly to third-party telemetry without a shared schema (timestamp, level, service, worker_type, component, metadata).

## 2. Audit Logging Discipline

- **Use AuditLogger**: Security-sensitive actions (role changes, token issuance, onboarding, destructive operations) must call `AuditLogger.getInstance().log(entry)` as seen in `backend/src/lib/audit-logger.ts`. It writes to both the `audit_logs` table and the Fluent Bit endpoint, guaranteeing persistence and observability.
- **Entry content**: Provide `action`, `details`, `severity` (`Low`/`Medium`/`High`), and user context (`userId`, `userName`, `userEmail`). Always include request metadata (`requestId`, `clientIp`, `userAgent`) so each record can be traced back to a request.
- **Failure handling**: The audit logger retries both sinks in parallel (`Promise.all`). If Fluent Bit is unreachable, log the failure locally but do not skip the audit entry—the database write is the canonical compliance record. Feature handlers should `await auditLog(...)` before acknowledging success.

## 3. Permission Enforcement Workflow

- **Authenticate & authorize**: All new endpoints must use the `authenticate` middleware (Kratos → Kong headers → JWT). Afterward, apply `authorizeWithOPA` so the gateway’s RBAC policy is enforced again inside the service.
- **Backend role checks**: For ultra-critical endpoints (e.g., metrics `/metrics` or any admin dashboard), layer `requireRole` on top of OPA. Don’t duplicate role lists; import them from `gateway/opa/policies/rbac.rego` and document any divergence in the feature spec.
- **Role additions**: Introducing a new role requires updating the Prisma `role` type, Kratos schema traits, and the OPA policy. Make sure the role appears in issued JWTs and seeded demo data to keep downstream logic consistent.
- **Audit permission changes**: Whenever permissions change, log before/after states. Example: when granting `manager` privileges, capture both the previous role and the new role in the audit `details` field so compliance can see what changed.

## References

- `backend/src/lib/logger.ts`
- `backend/src/lib/audit-logger.ts`
- `backend/src/lib/prisma.ts`
- `backend/src/lib/opa.ts`
- `gateway/opa/policies/rbac.rego`
