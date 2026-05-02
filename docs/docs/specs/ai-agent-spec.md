# AI Assistant & Tooling Constraints

This spec captures the operational, security, and behavioral constraints that every AI-agent feature must respect. The `ai-service` (see `ai-service/src/routes/chat.routes.ts` and `ai-service/src/index.ts`) is the single source of truth for conversations, tool execution, and policy generation.

## 1. Architecture & Observability

- **Express-based host**: The service runs on Express with `helmet`, `cors`, `morgan`, and JSON parsing enabled (`ai-service/src/index.ts`). Kong forwards `/api/ai` and `/api/agent` requests without stripping the path, so the router expects the full path.
- **Tracing**: OpenTelemetry is initialized via `ai-service/src/tracing.ts`, exporting to `PHOENIX_COLLECTOR_ENDPOINT` (default `http://phoenix:4317`). Every handler uses the `ai-service` tracer to annotate spans and push attributes for Phoenix.
- **HTTP keep-alive**: The OpenAI client (`OpenAI` from `openai` in `chat.routes.ts`) is constructed with shared `http.Agent`/`https.Agent` instances (keepAlive, maxSockets), 60 s timeout, and `maxRetries=2`.

## 2. Authentication & Access

- **Preferred path**: Kong injects `X-User-Id`/`X-User-Role` headers after validating JWTs. `authenticate` first trusts these headers, populates `req.user`, and logs the decision.
- **Fallback**: If Kong headers are missing, the code falls back to verifying a bearer JWT with `JWT_SECRET` (or the development fallback `your-secret-key`), so any future feature must ensure tokens include `userId/sub` and `role`.
- **Session invariants**: Every route under `/api/agent` and `/api/ai` requires authentication; unauthenticated requests receive `401`.

## 3. Conversation & Chat Flow

- **AI user anchor**: Conversations always pair a human user with the synthetic `ai-agent@studio.local` user (role `compliance`). `getOrCreateAiUser` ensures this user exists before recording messages.
- **Endpoints**:
  * `GET /api/agent/conversations` and `GET /api/agent/conversations/:id/messages` list conversations scoped to the authenticated user, excluding AI-only threads in the human-facing chat UI.
  * `POST /api/agent/chat` is the central handler. It builds a system prompt seeded with the user’s role, current projects, and requested tools, persists the user message, executes tool calls when GPT requests them, logs responses, and appends assistant outputs to the conversation.
  * `POST /api/agent/preference` and `GET /api/agent/switch-view` let the UI persist dashboard view choices.
  * `POST /api/ai/policy-generate`, `GET /api/ai/templates`, and `GET /api/ai/user-context` orchestrate policy generation & onboarding context.
- **Observability hooks**: Every chat request wraps logic in an OpenTelemetry span, adds `session.id`, `user.id`, `llm.model_name`, attaches tool execution events, and records token usage under `llm.token_count.*`.

## 4. Tool Contracts (`ai-service/src/tools`)

Toolkit functions must sit in `ai-service/src/tools/implementations.ts`, return `ToolResponse` with `text`/optional `widget`, and never mutate shared state. The current registry exposes:

1. **Project management**
   * `show_project_creation_form` serves dropdown data for frameworks.
   * `submit_project_creation` posts to `POST /api/customer/projects` and requires the confirmation code `WIDGET_VERIFIED_X9`.
2. **Evidence & controls**
   * `upload_evidence_intent` renders an upload widget around a control.
   * `link_evidence` calls `/api/auditor/projects/:projectId/controls/:controlId/evidence/link` after injecting Kong headers.
3. **Compliance analytics**
   * `generate_compliance_graph`, `get_unified_compliance_summary`, and `get_compliance_projection` consume backend endpoints (`/api/customer/dashboard`, `/api/compliance/summary`, `/api/compliance/projection`) depending on user role.
4. **Agent & risk telemetry**
   * `get_agent_stats` reads `FLEET_SERVICE_URL/api/agents/stats`.
   * `get_risk_analysis` hits `/api/customer/risk/overview`.
5. **Search experiences**
   * `search_cybersecurity_standards` uses `VECTOR_STORE_URL` to query a vector store.
   * `search_project_documents` fans out to `DOCUMENT_RAG_URL/search`.
   * `get_document_context` hits `DOCUMENT_RAG_URL/context` for chunk-level detail.
   * `select_projects_for_search` fetches `/api/{customer|auditor}/projects` to build selectors.
6. **Human-in-the-loop**
   * `ask_confirmation` returns a button widget for asynchronous approvals.

Any new tool must declare JSON schema parameters, handle `context.userId`/`context.userRole`, and produce user-level telemetry via the optional span.

## 5. Policy & Template Generation

- **Templates**: Markdown policy files live under `ai-service/templates`. `/api/ai/policy-generate` reads the requested template, merges user `customizations`, and enriches it with context fetched from `GET /api/ai/user-context-internal` (backend service at `BACKEND_URL`).
- **Platform Guardrails**: The policy prompt instructs the model to act as “Kimi” (Moonshot AI) and refuse undesirable content. Responses are expected to be raw Markdown.

## 6. Deployment Configuration

- **Feature flags & env vars**:
  * `USE_AI_GATEWAY`: true routes requests via the Cloudflare AI Gateway (`/v1/.../compat`), otherwise the default Moonshot endpoint.
  * `MOONSHOT_API_KEY`, `GEMINI_API_KEY`, `GOOGLE_API_KEY`: whichever is provided becomes the active credential.
  * `MOONSHOT_MODEL`, `GEMINI_MODEL`: override the default `kimi-k2-turbo-preview`.
  * `BACKEND_URL`, `FLEET_SERVICE_URL`, `VECTOR_STORE_URL`, `DOCUMENT_RAG_URL`: base URLs each tool depends on.
  * `JWT_SECRET`: required for decrypting fallback tokens.
  * Logging/tracing endpoints: `PHOENIX_COLLECTOR_ENDPOINT`, `OTEL_SERVICE_NAME`.
- **HTTP clients**: All outbound requests (`axios`) pass the Kong headers (`X-User-Id`, `X-User-Role`) plus `Authorization` when available so the backend/RAG services can re-evaluate access via their RBAC layer.

## 7. Behavior Expectations

- **Tool error handling**: Tools catch axios errors, log `response.data.message`, and return user-friendly fallback text/widgets instead of bubbling raw stack traces.
- **Conversation consistency**: Tool outputs are stitched back into LLM context via `toolMessages`, and a final LLM pass runs when any tool returns data.
- **Allowlist**: The AI user and project data are persisted via Prisma (`conversation`, `message`, `conversationParticipant`). Future features must respect the same schema to keep historical transcripts consistent.
