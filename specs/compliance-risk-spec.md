# Compliance & Risk Constraints

This spec documents the feature constraints for the compliance scorecards, risk scoring, and findings feeds so every new dashboard or automation can depend on a single source of truth (`backend/src/services/compliance.service.ts`, `backend/src/services/risk.service.ts`, and `backend/src/routes/findings.ts`).

## 1. Data Scope & Demo Handling

- **Tenant scoping**: All compliance/risk APIs filter projects by the authenticated user’s role (customer, auditor, manager, admin) while guarding `isDemo` data via `showDemo` flags pulled from `DEMO_MANAGER_ID` and `shouldShowDemoData`. Demo projects may only surface to users without managers or when explicitly allowed; otherwise every query enforces `isDemo: false`.
- **Project gating**: Queries list only projects shared with the user (`projectShares`), assigned customers/auditors, or demo buckets. Dashboard statistics and risk/finding filters reuse the *exact same* where clauses to keep totals aligned.

## 2. Compliance Service Guarantees

- **Compliance score**: `ComplianceService.getComplianceStats` and other routes calculate progress as raw floating-point weighted averages (Sum of control progress / total count). Rounding is explicitly avoided in the backend to ensure high-precision data for UI visualization. The frontend typically renders these with one decimal place (e.g., `80.2%`).
- **Detailed overview**: `getDetailedComplianceOverview` returns the same control set, calculates `completionPercentage` (fully verified controls) plus `averageProgress` (aggregated progress), and surfaces the top-five missing controls for help widgets.
- **Unified summary**: `getUnifiedComplianceSummary` stitches `getDetailedComplianceOverview`, `RiskService.getCustomerRiskOverview`, and `AgentManagementService.getAgentStats` so AI tools and dashboards can show compliance + risk + agent counts in one call.
- **Graph projection**: `getProjection` proxies to `graphServiceUrl/api/projection`, passing user metadata and evidence counts. Failures log warnings but return an empty array so dashboards remain resilient.

## 3. Risk & Findings Behavior

- **Risk scoring**: `RiskService.calculateRiskScore` weights severities (Critical=100, High=50, Medium=25, Low=10, Info=5), caps results at 100, and defines `High` (>=80), `Medium` (>=40), `Low` otherwise. Only open/in-progress findings feed this score.
- **Findings API**: `GET /api/findings` applies identical demo-aware filtering and allows severity/status/category/integration pagination. `GET /api/findings/stats` mirrors the same filter to keep dashboard counts deterministic.
- **Finding detail**: `GET /api/findings/:id` returns integration data, agent info, assigned/resolved metadata, and comment threads, keeping results in sync with Prisma relations.
- **Backend integration**: Findings feed into compliance dashboards, risk calculations, and the AI assistant’s summary. Any new feature that mutates findings must respect the demo gating and severity weighting described in this spec.

## 4. Operational Expectations

- **Health & resilience**: Compliance endpoints catch Graph Service (`axios`) failures, returning `503` when the external service is down but otherwise letting Prisma errors bubble so Observability can alert.
- **Telemetry links**: The compliance summary includes `criticalGaps` from missing controls and `totalFindings` from the risk service; ensure new dashboards surface both values for parity.
- **Agent context**: The unified summary expects agent stats from `AgentManagementService`. When adding new agent metrics or filters, extend that service before touching the dashboard endpoint.

## References

- `backend/src/services/compliance.service.ts`
- `backend/src/services/risk.service.ts`
- `backend/src/services/agent-management.service.ts`
- `backend/src/routes/findings.ts`
- `backend/src/routes/compliance.ts`
