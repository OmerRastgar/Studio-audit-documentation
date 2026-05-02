# Endpoint Management Constraints

The Studio Platform’s endpoint management capability is anchored by FleetDM integration and endpoint-level telemetry. This spec keeps future endpoint controls aligned with the existing dashboards (`docs/docs/integrations/fleetdm.md`) and monitoring expectations.

## 1. FleetDM Integration Contract

- **Widgets** surface:
  * Endpoint Status (online/offline hosts)
  * Vulnerability Summary (critical/high/medium/low)
  * Compliance Score (percentage)
  * Recent Activity (security events)
  * Custom queries imported from FleetDM (SQL-based, validated before scheduling)
- **Automated reports** may be produced daily/weekly/monthly summarizing vulnerabilities, compliance, and risk posture; they must include context on thresholds and recipients (email, Slack, webhooks).
- **Alert types** documented in the integration guide (critical vulnerabilities with `CVSS > 7.0`, compliance failures, endpoint issues, suspicious events) must remain canonical when configuring new alerts or dashboards.
- **Notification channels** include in-app UI, email, Slack, custom webhooks, and must purposely include the configured `cooldown` settings documented in the YAML snippet.

## 2. Query & Data Retention Policies

- Custom FleetDM queries require:
  * Defining SQL in FleetDM, testing it, then referencing the query ID in Studio.
  * Scheduling runs to avoid heavy load (off-peak) and caching results when possible.
  * Documenting the purpose/outcome of each query, matching the data retention policy: host inventory 90 days, vulnerability data 365 days, compliance results 2 years, audit logs 7 years.
- Use the provided YAML `retention_policy` structure as the default; any deviation must be surfaced in the feature spec to ensure compliance (legal/regulatory) instrumentation is updated.

## 3. Operational & Alerting Expectations

- **Health checks** like `curl https://studio.example.com/api/integrations/fleetdm/health` must be part of any new automation to confirm connectivity.
- **Performance indicators**: API response <500ms, data sync success >99%, alert accuracy high, system availability 99.9%. Track metrics and raise incidents when these targets slip.
- **Debug mode** is enabled through YAML entries (`debug_config`) to capture API timeouts, retry attempts, and log levels; new features replicating this section should follow the same structure.

## 4. Security & Compliance

- API tokens must be encrypted, rotated regularly, and optionally restricted by IP; Slack/Google webhooks follow the same discipline outlined in the settings page.
- Endpoint data is treated as sensitive: any UI component displaying user counts or vulnerability details must filter by RBAC (admin/manager roles) and respect the `showDemo` toggles described elsewhere.
- Documented best practices (encrypt at rest, secure transit, audit trails) remain the default for endpoint data ingestion, alerting, and storage.

## References

- `docs/docs/integrations/fleetdm.md`
- `docs/docs/integrations/prowler.md`
- `frontend/src/components/dashboard/AgentDetailsDialog.tsx`
