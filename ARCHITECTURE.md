# Architecture

Poster piggybacks on LLVM SanCov to emit memory-related events during execution. These events are consumed by a sidecar process to do stack and heap visualizations.

## Components

### 1. Poster (The Language Runtime)
- **Role**: Acts as the core language runtime and execution engine.
- **Mechanism**: Instruments the execution to emit "SanCov-style" traces or events.
- **Responsibility**: 
    - Executes the user's code.
    - Emits detailed memory events (allocations, modifications, stack frame changes).
    - Functions as the "source of truth" for the program's state evolution.

### 2. Sidecar (The Visualizer)
- **Role**: A separate process that runs alongside Poster.
- **Mechanism**: Listens to the stream of events emitted by Poster.
- **Responsibility**:
    - Reconstructs the program's memory state (stack and heap) from the event stream.
    - Renders real-time or post-mortem visualizations of the memory.
    - Provides the "time travel" or "complexity aware" insights mentioned in the project goals.

## Data Flow

1.  **Execution**: User runs a Poster program.
2.  **Emission**: The Poster runtime executes instructions and emits binary or structured events corresponding to memory operations.
3.  **Consumption**: The Sidecar process intercepts or reads these events (e.g., via shared memory, pipe, or socket).
4.  **Visualization**: The Sidecar updates its internal model of the heap/stack and renders the visual representation for the user.
