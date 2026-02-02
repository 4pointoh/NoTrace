# Poker Timeline Visualization System Documentation

## Overview
This system visualizes the branching logic of a strip poker match as a node graph. It reads a game configuration (JSON) and a generated match scenario (CSV) to construct a timeline of all possible states, transitions, and "Game Over" conditions.

## Architecture
 The system is refactored into three distinct layers to separate data, processing logic, and visualization.

1.  **`PokerNodeData`** (Resource): Pure data container for a single node.
2.  **`PokerTimelineProcessor`** (Logic): Handles file parsing, state calculation, and connection mapping.
3.  **`PokerTimelineGraphEdit`** (View): Handles the Godot UI, node instantiation, and visual connections.

---

## 1. Data Structure (`PokerNodeData.gd`)
This class acts as the blueprint for a node. It contains no logic, only data required to render the node later.

### Key Properties
*   **Identity**: `row_id` (from CSV), `node_id` (unique, state-based).
*   **State Info**:
    *   `pre_opp_count` / `pre_player_count`: Items lost *before* this node triggers.
    *   `post_opp_count` / `post_player_count`: Items lost *after* this event triggers.
*   **Layout**: `position_offset` calculated during processing.
*   **Connections**:
    *   `next_player_loss_ids`: List of Node IDs where the **Player** is the next to strip.
    *   `next_opp_loss_ids`: List of Node IDs where the **Opponent** is the next to strip.
*   **Display**: Pre-computed strings for labels (`main_label_text`, `player_branch_label`, etc.) and colors.

---

## 2. Logic & Processing (`PokerTimelineProcessor.gd`)
This is the workhorse of the system. It runs in three stages:

### A. Parsing
1.  **Config**: Reads `boa_poker1_config.json` to determine participant IDs and clothing stack sizes.
2.  **CSV**: Reads `boa_poker1_generated.csv`. It groups rows by their unique event signature (stripper + items lost) to handle conditional variants as a single node.
    *   *Note*: Impossible nodes (where `pre_state` implies someone is already naked) are filtered out.

### B. State & Positioning Calculation
*   **State**: The processor deduces the "Pre" state from the "Post" state provided in the CSV.
    *   *Example*: If the CSV says "Lisa lost HAT;TOP" (2 items), then the **Pre** state must have been "Lisa lost HAT" (1 item).
*   **Positioning (Pachinko Layout)**:
    *   **X-Axis (Depth)**: Based on total items lost (`post_opp + post_player`). Progress moves right.
    *   **Y-Axis (Balance)**: Based on who is winning (`post_opp - post_player`).
        *   Higher = Player winning (Opponent losing more).
        *   Lower = Player losing.
    *   **Micro Offset**: A small Y-offset is applied depending on *who* stripped in this specific event, ensuring nodes with identical counts don't overlap perfectly if the path differs.

### C. Connection Mapping
The processor builds the connection graph **without** touching the UI.
1.  Nodes are indexed in a dictionary: `nodes_by_pre_state = { "2,1": [NodeA, NodeB] }`.
2.  For every node, it calculates its `post_state` (e.g., "2,1").
3.  It looks up "2,1" in `nodes_by_pre_state` to find all nodes that **start** where this node **ends**.
4.  These targets are added to `next_player_loss_ids` or `next_opp_loss_ids` depending on who strips in the target node.

---

## 3. Visualization (`PokerTimelineGraphEdit.gd`)
This script is now lightweight. It performs two passes:

1.  **Instantiation**: Loops through the `node_datas` array returned by the processor and creates visual `GraphNode` instances.
    *   *Future Integration*: This is where a custom `TimelineNode.tscn` scene will be instantiated.
2.  **Connecting**: Loops through the data again to draw lines.
    *   Since IDs are pre-computed, it simply asks: "Does Node A connect to Node B?" and draws the line.
    *   **Port 0 (Cyan)**: Connected to targets in `next_player_loss_ids`.
    *   **Port 1 (Pink)**: Connected to targets in `next_opp_loss_ids`.

## Connection Logic Summary

| Source Slot | Label Color | Logic Meaning | Connects To |
| :--- | :--- | :--- | :--- |
| **Port 0** | **Cyan** | Player loses next | Input Port of any node where `Stripper == Player` |
| **Port 1** | **Pink** | Opponent loses next | Input Port of any node where `Stripper == Opponent` |

## Graph Slots
*   **Slot 0**: Main Event Label + Input Port.
*   **Slot 1**: State Info (debug text).
*   **Slot 2**: Player Branch Output (Port 0).
*   **Slot 3**: Opponent Branch Output (Port 1).
*   **Slot 4**: "Play from here" Button.
