# Security Settings & 2FA Constraints

This spec clarifies how user-level security settings (password updates, 2FA, identity verification) are managed so any enhancement stays aligned with the Kratos-powered flows and backend expectations (`frontend/src/app/(app)/settings/page.tsx`, `backend/src/routes/auth.ts`).

## 1. Kratos Settings Flow

- **Flow initialization**: The security tab (`SecuritySettings` component) calls `kratos.createBrowserSettingsFlow()` to fetch UI nodes and the CSRF token before rendering the form.
- **Identity verification**: If Kratos returns 401/403 (expired session or privileged session required), the UI surfaces a branded card asking the user to “Verify Identity” via `/login?refresh=true&return_to=/settings?tab=security`.
- **Force change detection**: Query param `?reason=force_change` or `user.forcePasswordChange` triggers the Security tab to auto-surface that the user must change credentials; after successful password change, the page hits `POST /api/auth/ack-password-change` to clear the flag.

## 2. Form & Flow Expectations

- Injected nodes from Kratos include password inputs and, when necessary, `confirm_password` to ensure double entry. Additional hidden CSRF nodes must be carried in each submission payload (`flow.ui.nodes`).
- Submit handler posts to `kratos.updateSettingsFlow({ flow: flow.id, updateSettingsFlowBody: body })` and re-renders on validation errors.
- Use `toast` notifications for success/failure, and automatically refresh the session via `refreshSession()` when the forced change completes.

## 3. Two-Factor Authentication & Device Security

- Two-factor authentication is required for high-privilege roles (Admin, Super Admin) per the admin playbook; security flows must:
  * Surface status (enabled/disabled) on the Security tab.
  * Trigger device registration or security verification when toggled.
  * Enforce 2FA (e.g., OTP, WebAuthn) through Kratos settings page or a specialized webhook; specify the viable channels in feature specs.
- Device registration, IP restrictions, and activity monitoring requirements documented in `docs/docs/admin-guide/user-management.md` apply when toggling 2FA or changing security-sensitive settings.

## 4. Security Settings Auditing

- Every settings update (password change, 2FA toggle, integration credential refresh) should generate an audit entry (consider `AuditLogger`) to persist the action ID, user ID, and new security posture.
- If a change is triggered by a forced password requirement, ensure notifications propagate to the user’s manager and security team (matching the deactivation notification pattern).

## References

- `frontend/src/app/(app)/settings/page.tsx`
- `backend/src/routes/auth.ts`
- `docs/docs/admin-guide/user-management.md`
