# Document Retrieval (RAG) Constraints

This spec summarizes how the fastAPI-backed Document RAG service is expected to behave so search-related features (AI agent, frontend, automation) can rely on a predictable hybrid search surface.

## 1. Architecture & Runtime

- **FastAPI host** (`main.py`): The service exposes health (`GET /health`), stats (`GET /stats`), search (`POST /search`), and chunk-context (`POST /context`) endpoints. Lifespan hooks ensure the `RAGService` is fully ready (database connection + embedding/reranking models) before accepting traffic; startup failures raise runtime errors.
- **Core service** (`services/rag_service.py`): Combines:
  * **Semantic search** via SentenceTransformer embeddings stored in `pgvector` columns.
  * **Keyword search** using PostgreSQL full-text search (`ts_rank`).
  * **Reciprocal Rank Fusion** hybridization using `SEMANTIC_WEIGHT`/`KEYWORD_WEIGHT`.
  * **Cross-encoder reranking** (`CrossEncoder('cross-encoder/ms-marco-MiniLM-L-6-v2')`).
- **Access control helper** (`services/access_control.py`): Delegates permissions to the backend by hitting `/api/customer/projects/:id` and `/api/auditor/projects/:id`. The backend’s OPA policy is the ultimate authority.

## 2. Configuration & Environment

- `config.py` defines the deploy-time knobs:
  * `DATABASE_URL` (PostgreSQL with `pgvector`).
  * `EMBEDDING_MODEL` (must match the chunking worker’s model) and `EMBEDDING_DIMENSION`.
  * Hybrid search weights (`SEMANTIC_WEIGHT`/`KEYWORD_WEIGHT`), similarity threshold, and rerank size (`RERANK_TOP_K`).
  * `BACKEND_URL` (used by `AccessControlService`).
  * `MCP_ENABLED` (the service can expose Model Context Protocol endpoints for AI tooling).
  * Service-level settings: `HOST`, `PORT`, `LOG_LEVEL`.
- Any new feature requiring document search must document how it targets these configs (e.g., customizing `SIMILARITY_THRESHOLD` or embedding model).

## 3. Access Control & JWT

- All public endpoints expect Kong-verified JWTs (`Authorization: Bearer ...`) plus the `X-User-Id`/`X-User-Role` headers. `main.py` strips the Bearer token for downstream calls, and `AccessControlService` forwards the same credentials to the backend.
- Permission checks are performed on the backend; the RAG service simply observes HTTP 200 responses. On failure, it logs a warning and returns an empty result or raises `403`.
- The service always “fails closed”: any exception in `verify_project_access` or the backend lookup results in denying the request.

## 4. Search Flow Guarantees

- **Semantic stage**: Queries are embedded (`SentenceTransformer.encode`) and compared using `1 - (dc.vector <=> query)`; only `evidence.chunking_status = 'COMPLETED'` rows are visible.
- **Keyword stage**: PostgreSQL full-text search uses `to_tsvector`/`plainto_tsquery`, normalizes ranks to [0,1], and participates in the fusion step.
- **Hybrid fusion**: RRF merges the two lists by weighting `SEMANTIC_WEIGHT` and `KEYWORD_WEIGHT` while honoring `limit + 2` results.
- **Cross-encoder rerank**: The top N results are reranked with `CrossEncoder` to produce the final similarity scores. Only the top `limit` entries are returned.
- **Chunk context**: `POST /context` pulls `context_window` chunks before and after the requested chunk to provide annotated snippets to the AI agent or UI.

## 5. Endpoints & Payloads

1. **`POST /search`** (`SearchRequest`/`SearchResponse`):
   * Body: `query`, `project_id`, `user_id`, optional `limit`, `evidence_types`, `min_similarity`.
   * Response: `results` array with chunk metadata, `total_results`, and mirrors the request for telemetry.
2. **`POST /context`**:
   * Body: `chunk_id`, `user_id`, `context_window`.
   * Response: `chunk`, `context_before`, `context_after`.
3. **`GET /health`**: Reports database/model readiness; returns `503` until embedding/reranker and DB connections succeed.
4. **`GET /stats`**: Returns counts of total chunks/evidence and exposure of `EMBEDDING_MODEL`.

## 6. Integration Requirements

- **AI tooling**: The AI service (`ai-service/src/tools`) relies on this service for `search_project_documents` and `get_document_context`; any API contract change must be synchronized with the agent tooling.
- **Chunking dependency**: Search results only surface fully chunked documents. Upstream chunking workers must set `chunking_status` to `COMPLETED` before data becomes queryable, and the spec enforces that through SQL filters.
- **MCP exposure**: When `MCP_ENABLED` is true, the service can expose tool endpoints to AI agents; the spec prohibits bypassing authentication even within MCP handlers.

## 7. Reliability & Telemetry

- Tight startup gating: If model loading or DB connection fails, the `lifespan` context raises, preventing the service from entering the ready state.
- Logging is centralized via Python’s `logging` module, mirroring the structured format used elsewhere. All warnings (access denied, search failure) are captured with context to help downstream alerting.
