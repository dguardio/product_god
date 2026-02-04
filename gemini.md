# Product God - Development State (2026-01-26)

## Project Overview
"Product God" represents an advanced RAG and AI application built on Ruby on Rails. It processes podcast transcripts to enable semantic search, knowledge graph exploration, and AI-driven content generation.

## 1. Implemented Features

### A. Knowledge Graph (Visual Explorer)
*   **Objective**: Visualize relationships between guests, topics, and companies.
*   **Tech**: Cytoscape.js (Frontend), Stimulus, recursive graph traversal.
*   **Key Files**:
    *   `app/models/graph_node.rb`, `graph_edge.rb`
    *   `app/services/knowledge_graph/extraction_service.rb`
    *   `app/javascript/controllers/graph_controller.js`
    *   `app/views/knowledge_graph/index.html.erb`
*   **Status**: **Complete**. Visualization is fixed (container height issue resolved). Search sidebar works.

### B. AI Playbooks (PRD-006)
*   **Objective**: Generate step-by-step markdown guides for specific product challenges.
*   **Tech**: Gemini 2.5 Pro, Commonmarker (Markdown rendering), Background Jobs.
*   **Workflow**: User Goal -> Vector Search -> LLM Synthesis -> Streamed Markdown.
*   **Key Files**:
    *   `app/models/playbook.rb`
    *   `app/services/playbook_generation_service.rb`
    *   `app/jobs/playbook_generation_job.rb`
    *   `app/views/playbooks/`
*   **Status**: **Complete**. Includes a loading state via Turbo Streams.

### C. Board Meeting Simulator (PRD-007)
*   **Objective**: Simulate a debate between "AI Personas" of podcast guests.
*   **Tech**: Multi-turn chat, Context Injection per persona, Real-time Turbo updates.
*   **Workflow**: User selects Board -> Opening Statements -> User Interjection -> AI Response.
*   **Key Files**:
    *   `app/models/board_meeting.rb`, `board_message.rb`
    *   `app/services/board_meeting_service.rb` (Orchestrator)
    *   `app/jobs/board_meeting_start_job.rb`, `board_meeting_reply_job.rb`
    *   `app/views/board_meetings/show.html.erb` (Grid layout)
*   **Status**: **Complete (MVP)**. Supports "Zoom-style" layout and interactive messaging.

## 2. Recent Architectural Decisions
*   **Async Processing**: adopted `ActiveJob` + `Turbo::Streams` for all long-running AI tasks (Playbooks, Meetings).
*   **Markdown**: Standardized on `commonmarker` for rendering high-fidelity content.
*   **Navigation**: Added a global persistent navbar in `application.html.erb`.
*   **Routing**: Set root to `search#index`.

## 3. Immediate Todos / Next Steps
1.  **CRITICAL**: Run the Knowledge Graph Backfill.
    *   Command: `rails knowledge_graph:backfill`
    *   *Why*: The Graph Explorer and Board Meeting Simulator rely on `GraphNode` data. Currently, they work but likely have sparse data until this task runs across all chunks.
2.  **Next Feature**: **Semantic Clip Search (PRD-008)**.
    *   Planning to allow users to search for specific *audio/video clips* based on meaning.
3.  **Refinement**:
    *   Add voice generation to Board Meetings?
    *   Enhance PDF export for Playbooks?

## 4. Environment
*   **Server**: `bin/dev` (Rails + Tailwind + JS watching).
*   **Database**: Postgres with `pgvector`.
*   **Dependencies**: Requires Redis for Sidekiq/Turbo Streams.

## 5. Resumption Guide
When coming back:
1.  Ensure Redis and Postgres are running.
2.  Start server: `bin/dev`.
3.  **Check if backfill was run**. If not, run it immediately to populate the personas.
