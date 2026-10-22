# Architecture

The package is `src/nanobio_backend`; keep the reusable layering from the Study Server while using the NanoBio scaffold:

```text
main.py -> api/v1 -> modules/<domain>/<feature>/models.py
                              -> validate.py (pure rules)
                              -> view.py (authorization, business, transaction)
                              -> query.py (bound SQL, no commit)
                       core -> config/database/security/responses/middleware
```

`create_app()` is the composition root. Inject a SQLAlchemy session factory for tests. Use synchronous route handlers for synchronous SQLAlchemy and blocking provider clients. Keep a request-scoped session. Do not put SQL or business rules in routers.

Module boundaries: auth/account; profile/cloud-sync; access/membership/quota; family; payments; sale/referral; wellness; admin; early-access; food-evidence; AI-content-report; sleep-safety; storage. Cross-module behavior goes through an explicit view/service function, not internal query imports.

Core has no product-specific policy. Views own transaction commit/rollback; queries use parameter binding and never commit. External calls must not hold a database transaction open.
