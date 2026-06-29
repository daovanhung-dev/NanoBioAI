# Fixbug - Admin Login No Permission

## Bug Description

After running `flutter run lib/main_admin.dart` and logging in with a valid admin account, the app shows an error screen:

**Error UI:**
- Icon: Cloud with slash (no access icon)
- Title: "Chưa tải được khu quản trị"
- Message: "Nabi chưa lấy được phiên Admin. Hãy thử lại."
- Button: "Thử lại"

## Root Cause

The issue occurs when a user successfully authenticates with Supabase Auth but is not assigned an admin role in the `admin_user_roles` table.

**UPDATE 2026-06-29 (Session 011):**

After adding logging system, discovered **second root cause**: **State management timing issue**.

**Flow with bug:**
1. User opens admin app → AdminController.build() runs → fetchSession() → `isAdmin=false` (no session yet)
2. AdminShellPage renders with `AsyncValue.data(isAdmin=false)` → shows blocking state
3. User enters credentials → login success → Router navigates to `/admin/dashboard`
4. Router redirect triggers `selectSection(dashboard)` → fetchSession() again → `isAdmin=true` ✅
5. **BUT** AdminShellPage still shows old blocking state because provider wasn't invalidated after login!

**Logs evidence:**
```
[SESSION] hasAuth=true, isAdmin=false  // Before login
[AUTH] sign_in_success
[NAV] dashboard
[SESSION] hasAuth=true, isAdmin=true   // After login - correct!
```

But UI doesn't update!

**Flow:**
1. User enters valid email/password → Supabase Auth succeeds
2. Router redirects to AdminShellPage (because session exists)
3. AdminController calls `fetchSession()` → RPC `get_my_admin_session`
4. RPC returns empty result (no admin role assigned to user)
5. `AdminSession.isAdmin` = false
6. UI displays blocking state

**Why this happens:**
- User account exists in Supabase Auth
- User record exists in `public.users` (auto-created by trigger)
- BUT: No record in `admin_user_roles` table for this user
- This happens when:
  - `docs/supabase/config.sql` has not been run
  - User's email doesn't match the bootstrapped admin (`dev.admin@nanobio.local`)
  - Admin role was not manually assigned

## Fix Applied

### 1. Improved Error Message (Session 009)

Updated `AdminShellPage` blocking state to show:
- Current logged-in email
- Clear instructions on how to fix:
  1. Run `config.sql` in Supabase
  2. Or manually bootstrap admin: `SELECT public.bootstrap_admin_by_email('email', 'super_admin');`
  3. Sign out and sign in again

### 2. Enhanced Datasource Error Handling

Added try-catch in `AdminSupabaseDatasource.fetchSession()` to:
- Detect empty RPC response
- Detect missing RPC function
- Provide actionable error messages

### 3. Updated README

Added comprehensive Setup and Troubleshooting sections in `lib/app_versions/admin/README.md`:
- Step-by-step setup instructions
- How to bootstrap admin users
- Common errors and fixes

## Files Changed

- `lib/app_versions/admin/features/admin_panel/presentation/pages/admin_shell_page.dart` - Updated blocking state message with email and instructions
- `lib/app_versions/admin/features/admin_panel/data/datasources/admin_supabase_datasource.dart` - Added error handling for empty/missing RPC
- `lib/app_versions/admin/README.md` - Added setup guide and troubleshooting

## How to Fix for User

**If you see this error, follow these steps:**

### Step 1: Run Supabase Config

In Supabase SQL Editor, run:
```sql
-- Run the full config file
-- File: docs/supabase/config.sql
```

### Step 2: Bootstrap Your Admin Account

In Supabase SQL Editor:

```sql
-- Replace with your email
SELECT public.bootstrap_admin_by_email('your.email@domain.com', 'super_admin');
```

### Step 3: Verify Admin Role

Check if your account has admin role:

```sql
SELECT 
  u.email,
  aur.role_code,
  aur.is_active,
  aur.granted_at
FROM public.users u
JOIN public.admin_user_roles aur ON aur.user_id = u.id
WHERE u.email = 'your.email@domain.com';
```

Expected result:
- role_code: `super_admin` (or other admin role)
- is_active: `true`

### Step 4: Sign Out and Sign In Again

In the admin app:
1. Click "Đăng xuất" button
2. Enter your email and password again
3. Should now load admin dashboard successfully

## Prevention

To prevent this in future:

1. **Always run `config.sql` first** before using admin app
2. **Use `bootstrap_admin_by_email()` function** to assign admin roles (don't manually INSERT)
3. **Document admin accounts** in team knowledge base
4. **Check admin role before granting access** (app now shows clear error)

## Related

- BD: `docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md`
- DD: `docs/DD/admin_dashboard/`, `docs/DD/admin_operations/`
- Supabase Schema: `docs/supabase/11-admin-access-dashboard.sql`
- RPC Definition: `docs/supabase/config.sql` (line 2108: `get_my_admin_session`)

## Verification

```bash
# Analyze admin code
dart analyze lib/main_admin.dart lib/app_versions/admin

# Run admin app
flutter run lib/main_admin.dart

# Expected behavior:
# 1. Login with admin account → loads dashboard
# 2. Login with non-admin account → shows clear error with instructions
```
