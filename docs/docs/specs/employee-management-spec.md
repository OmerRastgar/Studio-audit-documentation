# Employee Management Constraints

This spec captures how employee lifecycle workflows, deactivation, and role assignments operate so future HR and access-control features comply with the documented admin playbooks (`docs/docs/admin-guide/user-management.md`) and backend admin APIs (`backend/src/routes/admin.ts`, `backend/src/routes/manager.ts`).

## 1. Onboarding & Access Configuration

- Profiles include team/project metadata, geographic/work hours, and security settings (Two-Factor Auth required, mobile & remote access flags, email notifications).
- Profiles may record modification history (role changes, project links) for auditability; any new onboarding UI should persist these events through `NotificationService` or Prisma hooks referenced in `backend/src/routes/admin.ts`.

## 2. Deactivation & Offboarding

- Deactivation reasons include employee departure, role change, security incidents, compliance needs, or project completion.
- The documented mermaid flow (Access Review → Data Backup → Access Revocation → Notification → Documentation) must be mirrored by any automation (e.g., scheduled scripts) so that:
  * Active sessions and data access are enumerated before revocation.
  * System/email/mobile/remote access toggles are cleared atomically (see UI pseudo snippet).
  * Notifications go to user + manager + department + security.
  * Documentation (offboarding checklist, access review report, compliance docs, audit trail) is captured in logs or audit tables.

## 3. Role Management

- Super Admins, Admins, Managers, Auditors, Compliance users have distinct permission sets described in the admin guide; new RBAC changes must update those definitions plus `backend/src/routes/admin.ts` guards and OPA policies where necessary.
- Security requirements for roles:
  * Super Admin/Admin: MFA required, device registration, IP restrictions recommended, activity monitoring enabled.
  * Manager: MFA recommended, device registration optional, geographic restrictions and auditing expected.
  * Auditor/Compliance: Must preserve least privilege while enabling compliance view and annotations.
- Synchronize any role definition changes with Kratos traits and Prisma `role` union; unauthorized new roles must not appear in JWTs or OPA enforcer until fully defined.

## 4. Monitoring & Reporting

- Admin metrics (`GET /api/admin/metrics`) provide totals for projects, users, frameworks, controls, evidence, compliance progress, chunking distribution, and recent activity; use this endpoint for dashboards that surface employee-related KPIs.
- Project detail endpoints include frameworks, customers, auditors, controls, and evidence; use these when constructing employee-to-project access matrices or remediation checklists.
- Any employee management feature that modifies users should log notifications through `NotificationService` and update Graph relationships via `GraphService`.

## References

- `docs/docs/admin-guide/user-management.md`
- `backend/src/routes/admin.ts`
- `backend/src/routes/manager.ts`
