# Cloud Management Constraints

This spec codifies how Studio integrates with cloud infrastructure (AWS, Azure, GCP) via Prowler/CSPM scans and cloud-native controls (`docs/docs/integrations/prowler.md`, `backend/src/services/prowler.service.ts`), ensuring new cloud-facing features align with existing alerting, compliance, and data security guardrails.

## 1. Cloud Provider Coverage

- Supported clouds: AWS, Azure, GCP (per integration doc). Each provider may expose:
  * Specific services (EC2, IAM, CloudTrail, CloudWatch for AWS; Azure Storage, Kubernetes; GCP IAM, Cloud SQL, Cloud KMS).
  * CIS benchmarks (AWS v1.5/2.0, Azure tailored, GCP v1.4) plus frameworks like HIPAA, PCI-DSS, ISO 27001, NIST.
- Any new provider must map to the same YAML structure used for alert thresholds and retention policies, plus mirroring the `Cloud Security` section’s enumeration of required services.

## 2. Scan & Framework Workflow

- `ProwlerService.triggerScan`:
  * Creates provider (POST `/api/v1/providers`) with credentials, optional `uid`.
  * Triggers scan (POST `/api/v1/scans`) with `regions`, `scan_type`, `compliance_frameworks`.
  * Persists a `prowlerScan` record with `status: pending` and returns both external and local IDs.
- `getScans`/`getFindings` page results use Prisma tables for history.
- Cloud integrations rely on environment variable `PROWLER_API_URL` and secure credentials; features using those scans must handle secrets carefully (rotate tokens, store encrypted, limit scope).

## 3. Data & Alerting Guardrails

- Cloud data retention uses the documented policy (hosts 90d, vulns 365d, compliance 2y, audit logs 7y). Any feature storing derived data must piggyback on these retention values and mention expiration in spec.
- Alerts triggered by cloud scans should follow the YAML `alerts` snippet (per-type thresholds, channels, cooldowns). Ensure that newly introduced alert channels respect existing cooldown logic to avoid notification spam.
- Performance goals (API <500ms, sync success >99%) apply equally to cloud scans; new monitoring dashboards should display these KPIs and degrade gracefully when they slip.

## 4. Security Posture & Compliance

- Token/external credentials must be encrypted and rotated; instruct users to follow the security best practices in the integration guide (HTTPS, access controls, audit trails).
- Documented maintenance tasks (weekly alert reviews, monthly query updates, quarterly security audits) should remain in any uptime/Runbook features built around cloud management.
- Cloud management features must expose audit trails for every configuration change (providers, hosts, scan schedules) so compliance reviews can trace who changed what.

## References

- `docs/docs/integrations/prowler.md`
- `backend/src/services/prowler.service.ts`
