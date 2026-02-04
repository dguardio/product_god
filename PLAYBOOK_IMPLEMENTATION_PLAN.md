# AI Playbooks Implementation Plan (PRD-006)

## Objective
Enable users to generate structured, step-by-step "Playbooks" for specific product challenges (e.g., "How to price B2B SaaS") by synthesizing advice from multiple podcast episodes.

## 1. Database Schema

### `Playbook`
Stores the generated guides.
- `title`: string (The user's goal/query)
- `content`: text (The generated markdown guide)
- `sources`: jsonb (List of source chunk IDs/Episode titles used)
- `created_at`: datetime

## 2. Logic: `PlaybookGenerationService`

1.  **Retrieval Phase**:
    *   Initialize `RagSearchService`.
    *   Perform a broad semantic search for the user's goal to get a large set of relevant context (e.g., top 20-30 chunks).
2.  **Synthesis Phase**:
    *   **LLM Model**: Use `gemini-2.5-pro` (large context window is perfect here).
    *   **Prompt**: 
        *   "You are an expert product consultant."
        *   "Goal: [User Goal]"
        *   "Context: [List of Transcripts]"
        *   "Task: Create a detailed, actionable playbook. Use headers, checklists, and bullet points. Cite the specific guest/expert for each recommendation."
3.  **Output**:
    *   Save to `Playbook` model.

## 3. Web Interface

### Controller: `PlaybooksController`
- `index`: List all generated playbooks.
- `new`: Simple form to enter a "Goal".
- `create`: Calls service, redirects to `show`. (Consider using a background job + Turbo Stream for loading state, as generation might take 10-20s).
- `show`: Renders the Markdown content nicely.

### Views
- **New**: "What challenge are you facing?" input.
- **Show**: 
  - Title at top.
  - "Download PDF/Markdown" buttons.
  - Rendered content.
  - Sidebar: "Sources Used".

## 4. Dependencies
- **Markdown Renderer**: `commonmarker` (Fast, supports Github Flavored Markdown).
  - Vital for rendering **Checklists** (`- [ ]`), **Tables**, and **Task lists**.
  - We will style these with Tailwind's `@tailwindcss/typography` plugin (`prose` class) to make them look premium.
- **PDF Generation**: Browser print styling (CSS `@media print`).

## 5. Rich Formatting Strategy (Answering "Do we need JSON?")
We will use **Markdown** as the storage format. It is:
1.  **Native to LLMs**: Gemini generates high-quality Markdown naturally.
2.  **Rich**: Supports headers, bold, italics, lists, and **task lists** (checklists).
3.  **Flexible**: Allows the LLM to structure the advice freely without a rigid schema.
JSON would be necessary only if we wanted a "Progress Tracker" where the user checks off items and saves that state database-side. For a "Guide" or "Playbook" to read/follow, Markdown is superior.

## 5. Workflow
1. User enters: "How to hire a Head of Product"
2. System explains: "Looking for advice from various episodes..." (Loading UI)
3. System generates:
   - "Step 1: Define the role (Source: Gibson Biddle...)"
   - "Step 2: Sourcing (Source: Reforge episode...)"
4. User views and saves/prints.
