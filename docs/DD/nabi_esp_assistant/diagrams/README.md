# Diagrams — NABI_ESP_ASSISTANT

The proposed BLE/AI/WebSocket sequence is in [Overall.md](../Overall.md#3-luồng-đề-xuất). The following state diagram is the release target, not current runtime behavior.

```mermaid
stateDiagram-v2
    [*] --> ReviewPending
    ReviewPending --> CheckingLocalAI: approvals complete + release flag
    CheckingLocalAI --> NeedsSetup: GGUF / Whisper / voice missing
    NeedsSetup --> CheckingLocalAI: setup complete
    CheckingLocalAI --> StartingHotspot: all local components ready
    StartingHotspot --> Pairing: hotspot + foreground service ready
    Pairing --> Connected: BLE config + OTA + WebSocket v3
    Connected --> Listening: listen.start acknowledged
    Listening --> Connected: listen.stop acknowledged
    Connected --> Reconnecting: socket/hotspot lost
    Reconnecting --> Connected: reconnect succeeds
    Connected --> Stopping: user or notification stops
    Pairing --> Stopping
    Stopping --> [*]
```

Current source stops at `ReviewPending`; no transition into network or AI session is implemented.
