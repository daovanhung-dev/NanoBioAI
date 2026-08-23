# diagrams/ — AI_CHAT / AI Chat

## Required Diagrams

| Diagram | Purpose | Related IDs | Status |
|---|---|---|---|
| context.mmd | Show actor, module, dependency, and data boundary. | AI_CHAT-Fxx | Planned |
| overall-flow.mmd | Summarize main flow and failure branches. | AI_CHAT-Fxx, AI_CHAT-FNxx | Planned |
| state-ai_chat.mmd | Document state lifecycle from BD Appendix B where applicable. | AI_CHAT-BRxx | Planned |
| sequence-core-flow.mmd | Sequence from View/API -> Use case -> Repository -> datasource/event/audit. | AI_CHAT-FNxx | Planned |
| sequence-voice-turn.mmd | Half-duplex sequence User -> STT -> Controller -> Repository -> Flutter datasource/GeminiRestClient -> Gemini -> TTS, including Stop/background cancellation. | AI_CHAT-F03, AI_CHAT-FN03, AI_CHAT-API03 | Documented in delta flow; optional Mermaid asset |
| state-voice-session.mmd | `idle -> listening -> thinking -> speaking -> listening`, error/Stop/background branches and generation guard. | AI_CHAT-F03, AI_CHAT-BR06..BR08 | Documented in Overall/Views; optional Mermaid asset |

## Notes
- Markdown flow tables in Overall/List_Features are the source until Mermaid files are added.
- Diagrams must not replace business rules or traceability tables.
- Do not include real user health data, payment evidence, secret, or production screenshot in diagrams.
