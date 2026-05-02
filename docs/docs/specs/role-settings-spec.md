# Role-Based Settings Constraints

This spec outlines what each role (user, admin, manager, auditor) can configure in the Settings area so UI controls, integrations, and security workflows remain in sync (`frontend/src/app/(app)/settings/page.tsx`, `docs/docs/admin-guide/user-management.md`).

## 1. User-Level Settings

- All users can edit their profile (name, bio, email locked, certifications for auditors) and manage integrations (Google, Jira, Slack) via the accordion UI. Builder functions like `IntegrationForm` mask existing secrets and only submit changed values.
- Users can test connections for each integration before saving; tests should only run once per save action to avoid hitting rate limits.
- Security tab requires a valid Kratos flow—users without MFA (non-admin roles) still go through the same settings flow but may see fewer nodes.

## 2. Admin Settings

- Admins unlock additional integration sections (MinIO, Kong) and can manage system-wide tokens. The integration accordion opens with extra items when `user.role === 'admin'`.
- Admins retain full security controls (MFA required, device registration, IP restrictions). They also have access to `manager` + `auditor` toggles via `docs/docs/admin-guide/user-management.md`.
- Admin-specific updates must log notifications (via `NotificationService`) and respect `Approval flows` for high-impact changes.

## 3. Manager & Auditor Settings

- Managers see a subset of integrations and limited security controls (MFA recommended, device registration optional). Their settings area may emphasize team compliance dashboards and project scoping.
- Auditors can add professional data (experience, certifications, team membership) and can be tied to compliance-specific data; the UI exposes these extra fields when `user.role === 'auditor'`.
- Manager/auditor changes feed into analytics (e.g., compliance progress) and integrate with `AgentManagementService` and `ComplianceService` to update dashboards; any new fields must propagate to these services via profile APIs (`/api/profile`, `/api/profile/integrations`).

## 4. Security Enforcement per Role

- Super Admin/Admin roles enforce MFA and security verification when hitting the security tab, while managers/auditors may only be recommended to use MFA but must still re-authenticate for critical updates.
- The Kratos settings flow will return different UI nodes based on privilege (e.g., requiring `auth_method`, `webauthn` nodes for admins); feature specs should document expected nodes per role.

## References

- `frontend/src/app/(app)/settings/page.tsx`
- `docs/docs/admin-guide/user-management.md`
- `backend/src/routes/auth.ts`
