# Evidence & Graph Relationships Constraints

This spec outlines the guarantees around how evidence is stored, linked, annotated, and analyzed so any new feature interacting with audit data can align with the backend’s expectations (`backend/src/routes/evidence.ts`, `backend/src/services/graph.service.ts`, `backend/src/services/analysis.service.ts`).

## 1. Access Control & Listing

- **Authenticated entry**: The `/api/evidence` router is gated by the shared `authenticate` middleware; every query must observe `req.user`.
- **Role-based filtering**: The list and stats endpoints only succeed when the requesting user matches one of the following:
  * Auditor/Reviewer assigned to the project.
  * Customer owning the project (or a demo user linked via `DEMO_MANAGER_ID`).
  * Manager (via `projectShares`) or admin when explicitly shared.
- **Demo visibility**: `showDemoProjects` flips to true when a new/demo user lacks a manager or inherits `DEMO_MANAGER_ID`, allowing them to view demo evidence without breaking RBAC.
- **Stats aggregation**: `/api/evidence/stats` groups evidence by `chunkingStatus` (`PENDING`, `PROCESSING`, `COMPLETED`, `FAILED`, `SKIPPED`) and always returns zero values for missing buckets.

## 2. Upload Flow

- **Permitted uploaders**: Only the assigned auditor or the owning customer (including demo mode) may upload evidence; managers and admins are explicitly excluded to preserve audit integrity.
- **Tag handling**:
  * Explicit `tags` from the client are upserted via `prisma.tag.upsert`.
  * Tags inherited from linked controls (via `projectControl` → `control.tags`) are merged into the final set.
- **Control links**: The request may supply `controlIds` that correspond to `projectControl` records; the backend connects the evidence to those controls and recalculates counts per `recalcEvidenceCounts`.
- **Chunking metadata**: Evidence starts with `chunkingStatus = 'PENDING'` and, if URL-based, `isUrlBased`/`downloadStatus` toggles so workers know to fetch and chunk it before it becomes search-visible.
- **Graph events**: After creation, the code enqueues Neo4j events for:
  * `linkEvidenceToTag`
  * `linkEvidenceUploader`
  * `linkEvidenceToProject`
  * `linkEvidenceToControl`
  * (Additional tag/control associations are also re-emitted during updates; see `GraphService` for the full event catalog.)

## 3. Update, Delete, Refresh

- **Updates**: `PUT /api/evidence/:id` lets auditors (for their project) and the uploader (customer) change filenames, controls, and tags. Tag sets are re-derived with the same upsert logic, and linked controls trigger `recalcEvidenceCounts`.
- **Delete guards**: Evidence may only be deleted by the auditor (or uploader when the auditor uploaded it) or the owning customer, and only if the parent project is not in `review_pending`, `completed`, or `approved` status.
- **Refresh**: `POST /api/evidence/:id/refresh` re-triggers downloads but only for `isUrlBased` evidence; auditors, the uploader, or managers may hit this endpoint. It resets `downloadStatus`/`chunkingStatus` to `PENDING` so the worker retries.

## 4. Annotations & AI Evaluation

- **Annotations**:
  * Both `GET /:id/annotations` and `POST /:id/annotations` apply the same role logic (manager, auditor/reviewer, customer, shared user).
  * Creating an annotation requires `text` and coordinates (`x`, `y`), optionally notifying the customer; the code logs the intent even though no email sending is implemented.
  * Responses return author details (`id`, `name`, `role`) for UI rendering.
- **AI analysis**: `POST /api/evidence/:id/analyze` delegates to `AnalysisService.analyzeEvidence`.
  * The service fetches evidence + linked controls, concatenates document chunks, prompts Gemini (`gemini-1.5-flash`), and parses the JSON result.
  * The parsed evaluation is stored in `evidence.evaluationResult` and includes per-control statuses (`pass`/`fail`/`partial`/`not_applicable`).

## 5. Graph Synchronization

- **Event queue**: `GraphService` enqueues jobs into `neo4jSyncQueue` to keep Neo4j in sync. Key events used by evidence flows include `linkEvidenceToProject`, `linkEvidenceToControl`, `linkEvidenceToTag`, and `linkEvidenceUploader`, but the service also supports linking auditors, managers, controls, and standards.
- **Eventual consistency**: Graph updates happen asynchronously; frontend features should not assume immediate graph reflections. Monitoring the queue/logs is the reliable way to detect failures.

## 6. Observability & Auditing

- **Debug logging**: The routes log key steps (tag resolution, graph operations, permission checks) to help operators trace difficult uploads.
- **Recalculation hooks**: `recalcEvidenceCounts` recomputes each `ProjectControl`’s evidence count before responding, keeping the control dashboards accurate.
