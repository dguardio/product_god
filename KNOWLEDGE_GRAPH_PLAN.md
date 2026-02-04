# Knowledge Graph Implementation Plan (PRD-003)

## Objective
Build a knowledge graph by extracting entities (People, Companies, Tools, etc.) and their relationships from podcast transcripts. This will enable structured querying (e.g., "Show all PM tools recommended by Lenny") and richer RAG context.

## 1. Database Schema

### `GraphNode`
Stores unique entities found across all episodes.
- `name`: string (Indexed, Unique)
- `label`: string (e.g., "Person", "Company", "Framework", "Book", "Tool")
- `description`: text (Optional summary)
- `properties`: jsonb (For extra metadata like URL, role, etc.)

### `GraphEdge`
Represents a relationship between two nodes, grounded in a specific transcript chunk.
- `source_node_id`: references `GraphNode`
- `target_node_id`: references `GraphNode`
- `relationship_type`: string (e.g., "WORKS_AT", "FOUNDED", "RECOMMENDS", "MENTIONS")
- `transcript_chunk_id`: references `TranscriptChunk`
- `properties`: jsonb (e.g., context snippet, confidence score)

## 2. Extraction Service: `KnowledgeGraph::ExtractionService`
A service that processes a `TranscriptChunk` using an LLM.

- **Prompt**:
  - Input: Chunk text.
  - Output: JSON object with `nodes` (list) and `edges` (list).
  - Instructions: extract entities and relationships, normalize names.
- **Logic**:
  - `find_or_create` Nodes by name/label.
  - Create Edges linking the nodes, attached to the chunk.

## 3. Worker: `KnowledgeGraph::ExtractJob`
- Background job to process chunks asynchronously.
- Idempotency consideration: Check if edges already exist for this chunk? Or just delete existing edges for this chunk before processing (re-extraction).

## 4. Backfill Strategy
- Rake task to enqueue jobs for all existing `TranscriptChunks`.
- Limit concurrency to avoid rate limits.

## 5. Querying & API -> `GraphSearchService`
- **Method**: `search_nodes(query)` using `GraphNode` vector search (embedding entity names/descriptions).
- **Method**: `find_path(node_a, node_b)` using recursive SQL or graph traversal.
- **Controller**: `KnowledgeGraphController`
  - `index`: Search interface.
  - `visualize`: Returns JSON for D3/Cytoscape.

## 6. Visualization (Frontend)
- **Library**: `cytoscape.js` (Robust, handles large graphs well).
- **View**: A dedicated "Explorer" page.
  - Interactive canvas.
  - Sidebar showing selected node details and linked transcripts.
  - Filters for relationship types (e.g., "Show only 'RECOMMENDS'").

## 7. Cost Estimate (Current Data)
Based on ~5,600 chunks:
- **Gemini 1.5 Flash**: ~$0.85 (Recommended for extraction)
- **Gemini 1.5 Pro**: ~$14.12
- **Recommendation**: Use `gemini-1.5-flash` for the bulk backfill. It is accurate enough for entity extraction and significantly cheaper/faster.

