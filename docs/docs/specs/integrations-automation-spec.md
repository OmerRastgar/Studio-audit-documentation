# Integrations & Automation Constraints

This spec captures the expectations for the platform’s third-party integrations and automation toolchains such as n8n workflows, Prowler scans, and document retrieval helpers so every new integration feature plugs into the existing guardrails.

## 1. n8n Workflows

- **Living documentation**: The workflow JSON shown in `docs/docs/integrations/n8n.md` illustrates how Studio triggers, parses, collects, and stores evidence via n8n nodes (`studioWebhook`, `function`, `httpRequest`, `studioApi`). Automated flows must:
  * Keep the `Studio Trigger` webhook secure by enforcing Kong’s JWT and RBAC before n8n receives events.
  * Use the `Parse Request` node to validate payloads (`JSON.parse` from `$input`), preventing malformed data from reaching backend APIs.
  * Respect the `Collect Evidence` URL template `={{ $json.data.source }}` by leaving it inside `{% raw %}` blocks when documenting to avoid MkDocs templating errors.
  * Always finish with `studioApi` actions (e.g., `uploadEvidence`) that supply explicit `claims`/tokens via Kong headers so backend auth middleware can correlate the request with a user.

## 2. Prowler Cloud Scans

- **API contract**: `backend/src/routes/prowler.ts` exposes `/scan`, `/scans`, `/scans/:id`, `/compliance-frameworks`, and `/scans/:id/findings`. Only `admin`/`manager` roles may trigger scans (`requireRole(['admin','manager'])`), while read endpoints remain behind standard authentication.
- **Service behavior**: `ProwlerService` (`backend/src/services/prowler.service.ts`) proxies calls to `${PROWLER_API_URL}`. It:
  * Creates a temporary provider (`POST /api/v1/providers`) with `credentials` before invoking `POST /api/v1/scans`.
  * Persists a local `prowlerScan` record for traceability and returns both the external scan ID and local ID.
  * Provides pagination-friendly `getScans`/`getFindings` helpers and a static list of compliance frameworks matching Prowler naming (CIS, PCI-DSS, HIPAA, etc.).
  * Emits clear error messages when the external API fails, and logs responses for post-mortem analysis.
- **Security note**: Cloud credentials are accepted raw and forwarded to Prowler, so integrations must handle secrets securely (encrypted storage, short TTL, audit logging).

## 3. Document Retrieval & Automation

- **RAG integration**: The Document RAG service (FastAPI, `document-rag-service/`) provides `/search` and `/context` endpoints used by AI tools (see `ai-service/src/tools/implementations.ts`). Each call forwards Kong’s JWT plus `X-User-Id`/`X-User-Role` headers and validates project access via `AccessControlService` (backend API + OPA).
- **Vector/keyword balance**: Search flows combine semantic embeddings (pgvector), keyword queries (PostgreSQL FTS), Reciprocal Rank Fusion, and cross-encoder reranking. New integrations must honor `SIMILARITY_THRESHOLD`, `SEMANTIC_WEIGHT`, and `KEYWORD_WEIGHT` defined in `document-rag-service/config.py`.
- **MCP tooling**: When `MCP_ENABLED`, this service can surface specialized tools for AI agents (`search_project_documents`, `get_document_context`). Any new tool must reuse the same authentication headers, debugging logs, and request quotas to avoid misaligned expectations.

## 4. Automation Principles

- **Fail-safe design**: Integrations should treat backend API responses as authoritative; we never bypass OPA/Kong by hitting services directly without the token headers shown in existing code paths.
- **Auditing & observability**: All automation events (n8n flows, Prowler scan triggers, Document RAG calls) log contextual identifiers (user IDs, integration IDs, project IDs). Maintain this pattern so logs/audit trails remain consistent.
- **Rate limiting**: Kong’s rate-limiting plugin protects `/api/auth`, `/api/ai`, `/api/agent`, and other API routes. Automation routes that touch these paths must factor the configured rate-limits into their scheduling logic to avoid throttling.

## References

- `docs/docs/integrations/n8n.md`
- `backend/src/routes/prowler.ts`
- `backend/src/services/prowler.service.ts`
- `document-rag-service/main.py`
- `document-rag-service/services/access_control.py`
- `document-rag-service/services/rag_service.py`
- `ai-service/src/tools/implementations.ts`
