# Board Meeting Simulator Implementation Plan (PRD-007)

## Objective
Simulate a debate/discussion between specific podcast guests (e.g., "Marty Cagan vs. Shreyas Doshi") on a user-defined product topic.

## 1. Database Schema

## 1. Database Schema

### `BoardMeeting`
Represents the simulation session.
- `topic`: string
- `guest_ids`: jsonb (Array of GraphNode IDs: e.g. `[1, 5]`)
- `status`: string (active, completed)

### `BoardMessage`
Stores the individual turns of the conversation.
- `board_meeting_id`: references `BoardMeeting`
- `sender_type`: string ('User' or 'AI')
- `sender_graph_node_id`: references `GraphNode` (nullable, only if sender_type is AI)
- `content`: text
- `sequence`: integer

## 2. Logic: `BoardMeetingService`

1.  **Orchestrator**:
    *   Manages the flow. Decides who speaks next.
    *   Supports two modes:
        1.  **Auto-Debate**: AIs talking to each other.
        2.  **User Injection**: User sends a message, AIs respond.

2.  **Context Loading (Smart Persona)**:
    *   When the meeting starts, load personas.
    *   Fetch specific "views" on the `topic` for each guest.

3.  **Interaction Loop**:
    *   **User Action**: Sends text ("Actually, we have low budget...").
    *   **System Action**:
        *   Constructs prompt with: Current History + New User Input.
        *   Asks LLM: "Given this new info, how does [Guest A] and [Guest B] react?"
        *   Generates next 1-2 responses.

## 3. Web Interface (Zoom-style)

### Views
- **New**: Select 'Board Members' (Avatars) and Topic.
- **Show**: 
  - **Grid Layout**: Display the selected 'Board Members' as video tiles (using placeholder images or generated ones).
  - **Chat/Transcript Panel**: scrolling history of the debate.
  - **User Input**: "Interject..." bar at the bottom.

## 4. Dependencies
- **Turbo Streams**: Vital for pushing new messages (chat bubbles) in real-time as the "Meeting" progresses.

