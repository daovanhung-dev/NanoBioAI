# Apply NanoBio AI Chat fix

Apply this package at the root of a current `daovanhung-dev/NanoBioAI` checkout.

## Option 1 — copy files

Copy the repository-relative files from this ZIP over the checkout.

## Option 2 — patch

```bash
git apply NanoBioAI_ai_chat_fix.patch
```

Then run the targeted validation commands listed in the worklog.

For the first Android smoke test, fully stop/rebuild the app rather than using
hot reload, because `BuildConfig.GEMINI_API_KEY` is generated at build time.

Do not add `.env` to source control or to the ZIP.
