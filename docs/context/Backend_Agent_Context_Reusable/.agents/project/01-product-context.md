# Product Context — Điền trước khi Codex viết code

> `PROJECT_STATUS: TEMPLATE_UNFILLED`. Không tạo schema/business rule khi TODO chưa được xác nhận.

## Metadata

- Project name: `TODO_PROJECT_NAME`
- Product vision/problem: `TODO_PRODUCT_GOAL`
- Runtime deployment type: `TODO_API_ONLY | API_AND_WORKERS | MODULAR_MONOLITH`
- Stakeholders/actors: `TODO_ACTORS`
- Target regions/privacy requirements: `TODO_REGION_COMPLIANCE`
- Nonfunctional priorities (latency, throughput, uptime, budget): `TODO_NFR`

## Actors / authorization

| Actor | Trust boundary | Rights | Forbidden actions |
|---|---|---|---|
| TODO | TODO | TODO | TODO |

## Business modules

| Module | Owner | Inputs | Outputs | DB tables | External deps | Status |
|---|---|---|---|---|---|---|
| TODO | TODO | TODO | TODO | TODO | TODO | `NOT_FOUND` |

## In/out of scope

- MVP scope: TODO
- Out of scope: TODO
- Data retention/deletion: TODO
- Regulatory/security constraints: TODO

## Contract sources

- `docs/contracts/*` hoặc API spec đã được duyệt: TODO
- Canonical schema/migrations source: TODO
- Ticket/AC/acceptance criteria: TODO

**Agent rule:** khi có yêu cầu làm nhanh nhưng thiếu chi tiết, tạo assumption minh bạch; tránh quyết định khó đảo ngược, đặc biệt schema, finance, auth, privacy. Không clone những business modules của Study2Work.
