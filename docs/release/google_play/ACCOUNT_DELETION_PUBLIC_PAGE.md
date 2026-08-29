# Public account-deletion page package

This repository does not contain a web host or a deploy credential, so the
public URL is `BLOCKED_EXTERNAL` until the product owner publishes this content
over HTTPS. Do not enter a repository URL, PDF URL, or an authenticated
Supabase URL in Play Console.

## Publish-ready copy

**Delete your NanoBio account and data**

NanoBio (package `com.nanobioai.app`) lets you permanently delete your account
and request deletion of the account data associated with it.

1. If you can open NanoBio, sign in and choose **Settings → Account → Yêu cầu
   xóa tài khoản**, then confirm the destructive action.
2. If you cannot open or reinstall NanoBio, email the support address listed on
   this page from the account email. Include `NanoBio account deletion` in the
   subject. Do not send a password, one-time code, purchase token, or health
   records in the email.
3. Support will verify account ownership and confirm when the request is
   complete. Requests are not fulfilled by asking for another user's data.

The deletion workflow removes the NanoBio account, account-scoped health and
wellness data, local account data after the in-app request, and owned
schedule-proof objects. Purchase reconciliation, moderation, or security
records may be retained in an unlinkable/minimized form only when required by
law or fraud prevention; the applicable retention period must be published in
the Privacy Policy.

The page must show the legal entity/developer name, a real support address,
the Privacy Policy link (**[PUBLIC PRIVACY POLICY URL]**), and a last-updated
date before it is submitted.

## Release wiring

Set `ACCOUNT_DELETION_URL` and `PRIVACY_POLICY_URL` in the release's public
configuration, expose both links from the in-app Settings screen, and verify
that each URL is reachable in an incognito browser without installing the app.

Status: `SOURCE_READY`; `RUNTIME_VERIFIED` and `CONSOLE_VERIFIED` require the
published page, release build, and Play Console entry.
