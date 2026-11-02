import { useEffect, useRef, useState } from "react";
import type { FormEvent, ReactNode } from "react";
import {
  AdminUserSummary,
  BackendAuthSession,
  BackendClient,
  BackendRequestError,
  Readiness,
  UserDataPage,
  UserDataSection,
  UserDetail,
  createBackendClient,
} from "./lib/backend-client";

const SECTIONS: Array<{ id: UserDataSection; label: string; icon: string }> = [
  { id: "profile", label: "Hồ sơ", icon: "◉" },
  { id: "health", label: "Sức khỏe", icon: "✚" },
  { id: "schedule", label: "Lịch & dinh dưỡng", icon: "▦" },
  { id: "membership", label: "Membership & thanh toán", icon: "◇" },
  { id: "family", label: "Gia đình", icon: "⌂" },
  { id: "sleep_safety", label: "Giấc ngủ an toàn", icon: "☾" },
  { id: "sale_rewards", label: "Sale & rewards", icon: "✦" },
  { id: "activity", label: "Hoạt động & audit", icon: "◷" },
  { id: "related", label: "Dữ liệu liên quan", icon: "⋯" },
];

type Notice = { tone: "success" | "error" | "warning" | "info"; text: string };
type ActionIntent =
  | { kind: "activate" }
  | { kind: "close" }
  | { kind: "reset" }
  | { kind: "grant" }
  | { kind: "extend"; subscriptionId: string; expectedEnd: string }
  | { kind: "revoke"; subscriptionId: string; providerManaged: boolean };

function keyForRequest(): string {
  return globalThis.crypto?.randomUUID?.() ?? `admin-${Date.now()}-${Math.random().toString(36).slice(2)}`;
}

function asText(value: unknown): string {
  if (value === null || value === undefined || value === "") return "—";
  if (typeof value === "boolean") return value ? "Có" : "Không";
  if (typeof value === "object") return JSON.stringify(value, null, 2);
  return String(value);
}

function asRecord(value: unknown): Record<string, unknown> {
  return value && typeof value === "object" && !Array.isArray(value)
    ? value as Record<string, unknown>
    : {};
}

function formatDate(value: unknown): string {
  if (!value) return "—";
  const date = new Date(String(value));
  return Number.isNaN(date.getTime())
    ? String(value)
    : new Intl.DateTimeFormat("vi-VN", { dateStyle: "medium", timeStyle: "short" }).format(date);
}

function getErrorMessage(error: unknown): string {
  if (error instanceof BackendRequestError) return error.message;
  if (error instanceof TypeError) return "Mất kết nối với API. Hãy kiểm tra mạng rồi thử lại.";
  return error instanceof Error ? error.message : "Có lỗi xảy ra. Vui lòng thử lại.";
}

export default function App() {
  const [client] = useState<BackendClient>(() => createBackendClient());
  const [session, setSession] = useState<BackendAuthSession | null>(null);
  const [adminUserId, setAdminUserId] = useState<string | null>(null);
  const [authLoading, setAuthLoading] = useState(true);
  const [accessDenied, setAccessDenied] = useState("");
  const [readiness, setReadiness] = useState<Readiness | null>(null);
  const [notice, setNotice] = useState<Notice | null>(null);
  const [searchTerm, setSearchTerm] = useState("");
  const [searchBusy, setSearchBusy] = useState(false);
  const [searchError, setSearchError] = useState("");
  const [users, setUsers] = useState<AdminUserSummary[]>([]);
  const [selectedUser, setSelectedUser] = useState<AdminUserSummary | null>(null);
  const [userDetail, setUserDetail] = useState<UserDetail | null>(null);
  const [detailReason, setDetailReason] = useState("");
  const [detailBusy, setDetailBusy] = useState(false);
  const [detailError, setDetailError] = useState("");
  const [activeSection, setActiveSection] = useState<UserDataSection>("profile");
  const [sectionPage, setSectionPage] = useState(1);
  const [sectionData, setSectionData] = useState<UserDataPage | null>(null);
  const [sectionBusy, setSectionBusy] = useState(false);
  const [sectionError, setSectionError] = useState("");
  const [detailReasonOpen, setDetailReasonOpen] = useState(false);
  const [pendingUser, setPendingUser] = useState<AdminUserSummary | null>(null);
  const [reasonDraft, setReasonDraft] = useState("");
  const [intent, setIntent] = useState<ActionIntent | null>(null);
  const [editOpen, setEditOpen] = useState(false);
  const [createOpen, setCreateOpen] = useState(false);
  const [temporaryPassword, setTemporaryPassword] = useState<{ label: string; value: string } | null>(null);

  useEffect(() => {
    let active = true;
    const check = async () => {
      const status = await client.checkReadiness();
      if (active) setReadiness(status);
    };
    void check();
    const timer = window.setInterval(() => void check(), 30_000);
    return () => {
      active = false;
      window.clearInterval(timer);
    };
  }, [client]);

  useEffect(() => {
    let active = true;
    void (async () => {
      try {
        const current = await client.getCurrentSession();
        if (!active || !current) return;
        setSession(current);
        if (!current.mustChangePassword) await verifySuperAdmin(current);
      } catch (error) {
        if (active) setNotice({ tone: "error", text: getErrorMessage(error) });
      } finally {
        if (active) setAuthLoading(false);
      }
    })();
    return () => {
      active = false;
    };
  }, [client]);

  useEffect(() => {
    if (!session || !adminUserId) return;
    let active = true;
    const timer = window.setTimeout(() => {
      setSearchBusy(true);
      setSearchError("");
      void client.searchUsers(searchTerm).then((result) => {
        if (active) setUsers(result);
      }).catch((error: unknown) => {
        if (active) {
          setUsers([]);
          setSearchError(getErrorMessage(error));
        }
      }).finally(() => {
        if (active) setSearchBusy(false);
      });
    }, searchTerm ? 250 : 0);
    return () => {
      active = false;
      window.clearTimeout(timer);
    };
  }, [client, session, adminUserId, searchTerm]);

  useEffect(() => {
    if (!selectedUser || !detailReason || !userDetail) return;
    let active = true;
    setSectionBusy(true);
    setSectionError("");
    setSectionData(null);
    void client.getUserData(selectedUser.id, activeSection, sectionPage, detailReason)
      .then((result) => {
        if (active) setSectionData(result);
      })
      .catch((error: unknown) => {
        if (active) setSectionError(getErrorMessage(error));
      })
      .finally(() => {
        if (active) setSectionBusy(false);
      });
    return () => {
      active = false;
    };
  }, [client, selectedUser?.id, detailReason, userDetail, activeSection, sectionPage]);

  async function verifySuperAdmin(current: BackendAuthSession): Promise<void> {
    try {
      const admin = await client.fetchAdminSession();
      if (!admin.roles.includes("super_admin")) {
        setAccessDenied("Tài khoản này chưa được cấp quyền super_admin.");
        setAdminUserId(null);
        setSession(null);
        await client.signOut().catch(() => undefined);
        return;
      }
      setAccessDenied("");
      setAdminUserId(admin.user_id || current.user.id);
    } catch (error) {
      setAdminUserId(null);
      setNotice({ tone: "error", text: getErrorMessage(error) });
    }
  }

  async function handleLogin(identifier: string, password: string): Promise<void> {
    setNotice(null);
    const current = await client.signIn(identifier, password);
    setSession(current);
    if (current.mustChangePassword) return;
    await verifySuperAdmin(current);
  }

  async function handlePasswordChange(password: string): Promise<void> {
    const current = await client.changePassword(password);
    setSession(current);
    await verifySuperAdmin(current);
  }

  async function handleSignOut(): Promise<void> {
    await client.signOut().catch(() => undefined);
    setSession(null);
    setAdminUserId(null);
    setSelectedUser(null);
    setUserDetail(null);
    setAccessDenied("");
  }

  async function submitDetailReason(event: FormEvent<HTMLFormElement>): Promise<void> {
    event.preventDefault();
    if (!pendingUser || reasonDraft.trim().length < 2) return;
    setDetailBusy(true);
    setDetailError("");
    try {
      const details = await client.getUserDetails(pendingUser.id, reasonDraft.trim());
      setSelectedUser(pendingUser);
      setUserDetail(details);
      setDetailReason(reasonDraft.trim());
      setActiveSection("profile");
      setSectionPage(1);
      setDetailReasonOpen(false);
      setPendingUser(null);
      setReasonDraft("");
    } catch (error) {
      setDetailError(getErrorMessage(error));
    } finally {
      setDetailBusy(false);
    }
  }

  async function reloadSelectedUser(): Promise<void> {
    if (!selectedUser || !detailReason) return;
    try {
      const details = await client.getUserDetails(selectedUser.id, detailReason);
      setUserDetail(details);
      await reloadUsers();
    } catch (error) {
      setNotice({ tone: "error", text: `Đã cập nhật nhưng chưa tải lại được hồ sơ: ${getErrorMessage(error)}` });
    }
  }

  async function reloadUsers(): Promise<void> {
    try {
      setUsers(await client.searchUsers(searchTerm));
    } catch (error) {
      setSearchError(getErrorMessage(error));
    }
  }

  async function executeIntent(action: ActionIntent, reason: string, days: number): Promise<void> {
    if (!readiness?.ready) {
      setNotice({ tone: "warning", text: "API chưa sẵn sàng. Thao tác ghi đang bị khóa." });
      return;
    }
    if (!selectedUser) return;
    setIntent(null);
    setNotice(null);
    try {
      if (action.kind === "activate") {
        await client.updateStatus(selectedUser.id, {
          status: "active",
          reason,
          idempotency_key: keyForRequest(),
        });
        setNotice({ tone: "success", text: "Tài khoản đã được kích hoạt và có thể đăng nhập." });
      } else if (action.kind === "close") {
        await client.updateStatus(selectedUser.id, {
          status: "closed",
          reason,
          idempotency_key: keyForRequest(),
        });
        setNotice({ tone: "success", text: "Tài khoản đã được đóng; phiên đăng nhập đã bị thu hồi." });
      } else if (action.kind === "reset") {
        const result = await client.resetPassword(selectedUser.id, reason, keyForRequest());
        const password = typeof result.temporary_password === "string" ? result.temporary_password : "";
        if (password) {
          setTemporaryPassword({ label: `Mật khẩu tạm của ${selectedUser.title}`, value: password });
        } else {
          setNotice({ tone: "warning", text: "Mật khẩu của lần reset trước không thể xem lại. Hãy tạo yêu cầu reset mới nếu cần." });
        }
      } else if (action.kind === "grant") {
        const startsAt = new Date();
        const endsAt = new Date(startsAt.getTime() + days * 86_400_000);
        await client.grantMembership({
          user_id: selectedUser.id,
          plan_code: "plus",
          starts_at: startsAt.toISOString(),
          ends_at: endsAt.toISOString(),
          preserve_existing_paid_plan: true,
          reason,
          idempotency_key: keyForRequest(),
        });
        setNotice({ tone: "success", text: `Đã cấp Plus trong ${days} ngày.` });
      } else if (action.kind === "extend") {
        await client.adjustMembership({
          user_id: selectedUser.id,
          subscription_id: action.subscriptionId,
          operation: "add_days",
          days,
          expected_ends_at: action.expectedEnd,
          reason,
          idempotency_key: keyForRequest(),
        });
        setNotice({ tone: "success", text: `Đã gia hạn thêm ${days} ngày.` });
      } else {
        const result = await client.revokeMembership({
          user_id: selectedUser.id,
          subscription_id: action.subscriptionId,
          reason,
          idempotency_key: keyForRequest(),
        });
        setNotice({
          tone: result.billing_provider_managed === true ? "warning" : "success",
          text: result.billing_provider_managed === true
            ? "Đã thu hồi Plus trong NanoBio. Gói thanh toán bên ngoài vẫn có thể tiếp tục gia hạn."
            : "Đã kết thúc quyền Plus trong NanoBio.",
        });
      }
      await reloadSelectedUser();
    } catch (error) {
      setNotice({ tone: "error", text: getErrorMessage(error) });
    }
  }

  async function submitProfile(event: FormEvent<HTMLFormElement>): Promise<void> {
    event.preventDefault();
    if (!selectedUser || !readiness?.ready) return;
    const form = new FormData(event.currentTarget);
    const reason = String(form.get("reason") ?? "").trim();
    if (reason.length < 2) return;
    const phone = String(form.get("phone") ?? "").trim();
    const email = String(form.get("email") ?? "").trim();
    try {
      await client.updateProfile(selectedUser.id, {
        full_name: String(form.get("full_name") ?? "").trim(),
        phone: phone || null,
        email: email || null,
        gender: String(form.get("gender") ?? "") || null,
        birth_year: String(form.get("birth_year") ?? "")
          ? Number(form.get("birth_year"))
          : null,
        reason,
        idempotency_key: keyForRequest(),
      });
      setEditOpen(false);
      setNotice({ tone: "success", text: "Đã cập nhật hồ sơ." });
      await reloadSelectedUser();
    } catch (error) {
      setNotice({ tone: "error", text: getErrorMessage(error) });
    }
  }

  async function createAccounts(rows: Array<{ phone: string; full_name: string; email?: string }>, reason: string) {
    if (!readiness?.ready) throw new Error("API chưa sẵn sàng. Không thể tạo tài khoản.");
    const results: Array<{ name: string; phone: string; password?: string; error?: string }> = [];
    for (const row of rows) {
      try {
        const created = await client.createAccount({ ...row, reason, idempotency_key: keyForRequest() });
        results.push({
          name: row.full_name,
          phone: row.phone,
          password: typeof created.temporary_password === "string" ? created.temporary_password : undefined,
          error: created.temporary_password_unavailable === true
            ? "Mật khẩu đã tạo trước đó không thể xem lại."
            : undefined,
        });
      } catch (error) {
        results.push({ name: row.full_name, phone: row.phone, error: getErrorMessage(error) });
      }
    }
    await reloadUsers();
    return results;
  }

  if (authLoading) return <ScreenMessage title="Đang kiểm tra phiên đăng nhập…" readiness={readiness} />;
  if (!session) {
    return (
      <>
        <ReadinessBanner readiness={readiness} />
        {accessDenied && <div className="screen-notice" role="alert">{accessDenied}</div>}
        <LoginScreen onSubmit={handleLogin} />
      </>
    );
  }
  if (session.mustChangePassword) {
    return (
      <>
        <ReadinessBanner readiness={readiness} />
        <PasswordChangeScreen onSubmit={handlePasswordChange} />
      </>
    );
  }
  if (!adminUserId) {
    return (
      <>
        <ReadinessBanner readiness={readiness} />
        <ScreenMessage
          title={readiness?.ready ? "Chưa thể xác minh quyền quản trị." : "API chưa sẵn sàng để xác minh quyền quản trị."}
          readiness={readiness}
          notice={notice}
          action={readiness?.ready
            ? <button className="button button-secondary" onClick={() => session && void verifySuperAdmin(session)}>Thử xác minh lại</button>
            : undefined}
        />
      </>
    );
  }

  const currentSummary = selectedUser
    ? users.find((user) => user.id === selectedUser.id) ?? selectedUser
    : null;
  const detailUser = asRecord(userDetail?.user);
  const tables = sectionData?.tables ?? {};
  const maxPages = Math.max(1, ...Object.values(tables).map((table) => table.pages));

  return (
    <div className="app-shell">
      <aside className="sidebar">
        <div className="brand-lockup">
          <div className="brand-symbol" aria-hidden="true">N</div>
          <div><strong>NanoBio</strong><span>ADMIN WORKSPACE</span></div>
        </div>
        <div className="nav-label">QUẢN TRỊ</div>
        <nav aria-label="Điều hướng chính">
          <button className="nav-item nav-item-active" type="button"><span className="nav-icon">♙</span>Người dùng</button>
        </nav>
        <div className="sidebar-foot">
          <span className="avatar-small">{session.user.email?.slice(0, 1).toUpperCase() || "N"}</span>
          <div className="sidebar-user"><strong>{session.user.email || "Super Admin"}</strong><span>Super Admin</span></div>
          <button className="icon-button logout-button" type="button" onClick={handleSignOut} aria-label="Đăng xuất" title="Đăng xuất">↗</button>
        </div>
      </aside>

      <main className="main-area">
        <ReadinessBanner readiness={readiness} inline />
        <header className="topbar">
          <div>
            <div className="breadcrumb">Quản trị <span>/</span> Người dùng</div>
            <h1>Quản lý người dùng</h1>
            <p className="page-subtitle">Tìm kiếm hồ sơ, quản lý tài khoản và quyền thành viên.</p>
          </div>
          <button className="button button-primary" type="button" onClick={() => setCreateOpen(true)} disabled={!readiness?.ready}>
            <span aria-hidden="true">＋</span> Tạo tài khoản
          </button>
        </header>

        {notice && <NoticeBanner notice={notice} onDismiss={() => setNotice(null)} />}

        <section className="workspace-card" aria-labelledby="users-heading">
          <div className="workspace-toolbar">
            <div>
              <h2 id="users-heading">Danh sách tài khoản</h2>
              <p>Tra cứu theo tên, số điện thoại hoặc email.</p>
            </div>
            <div className="result-count"><strong>{users.length}</strong><span>kết quả</span></div>
          </div>
          <label className="search-box">
            <span className="search-symbol" aria-hidden="true">⌕</span>
            <span className="visually-hidden">Tìm theo tên, số điện thoại hoặc email</span>
            <input
              value={searchTerm}
              onChange={(event) => setSearchTerm(event.target.value)}
              placeholder="Nhập tên, số điện thoại hoặc email…"
              type="search"
            />
            {searchTerm && <button type="button" className="clear-search" onClick={() => setSearchTerm("")} aria-label="Xóa tìm kiếm">×</button>}
          </label>
          {searchError && <InlineError message={searchError} />}
          <UserTable
            users={users}
            loading={searchBusy}
            query={searchTerm}
            onSelect={(user) => {
              setPendingUser(user);
              setReasonDraft("");
              setDetailError("");
              setDetailReasonOpen(true);
            }}
          />
        </section>

        <footer className="page-footnote"><span aria-hidden="true">◈</span> Dữ liệu sức khỏe chỉ xem. Mỗi lượt xem hồ sơ được ghi audit theo lý do truy cập.</footer>
      </main>

      {detailReasonOpen && pendingUser && (
        <ReasonModal
          title="Lý do truy cập hồ sơ"
          description={`Hãy ghi mục đích xem dữ liệu của ${pendingUser.title}. Lý do sẽ được lưu trong audit.`}
          reason={reasonDraft}
          busy={detailBusy}
          error={detailError}
          confirmLabel="Mở hồ sơ"
          onReasonChange={setReasonDraft}
          onClose={() => { setDetailReasonOpen(false); setPendingUser(null); }}
          onSubmit={submitDetailReason}
        />
      )}

      {selectedUser && userDetail && (
        <UserDrawer
          user={currentSummary ?? selectedUser}
          detail={detailUser}
          section={activeSection}
          data={sectionData}
          loading={sectionBusy}
          error={sectionError}
          page={sectionPage}
          maxPages={maxPages}
          ready={readiness?.ready === true}
          onClose={() => { setSelectedUser(null); setUserDetail(null); setDetailReason(""); setSectionData(null); }}
          onChangeSection={(section) => { setActiveSection(section); setSectionPage(1); }}
          onPage={(page) => setSectionPage(page)}
          onEdit={() => setEditOpen(true)}
          onIntent={setIntent}
        />
      )}

      {intent && selectedUser && (
        <ActionModal
          intent={intent}
          userName={selectedUser.title}
          ready={readiness?.ready === true}
          onClose={() => setIntent(null)}
          onConfirm={(reason, days) => executeIntent(intent, reason, days)}
        />
      )}

      {editOpen && selectedUser && (
        <EditProfileModal
          user={detailUser}
          ready={readiness?.ready === true}
          onClose={() => setEditOpen(false)}
          onSubmit={submitProfile}
        />
      )}

      {createOpen && (
        <CreateAccountsModal
          ready={readiness?.ready === true}
          onClose={() => setCreateOpen(false)}
          onCreate={createAccounts}
        />
      )}

      {temporaryPassword && (
        <TemporaryPasswordModal
          label={temporaryPassword.label}
          password={temporaryPassword.value}
          onClose={() => setTemporaryPassword(null)}
        />
      )}
    </div>
  );
}

function LoginScreen({ onSubmit }: { onSubmit: (identifier: string, password: string) => Promise<void> }) {
  const [error, setError] = useState("");
  const [busy, setBusy] = useState(false);
  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const form = new FormData(event.currentTarget);
    setBusy(true);
    setError("");
    try {
      await onSubmit(String(form.get("identifier") ?? ""), String(form.get("password") ?? ""));
    } catch (reason) {
      setError(getErrorMessage(reason));
    } finally {
      setBusy(false);
    }
  }
  return (
    <main className="auth-page">
      <section className="auth-card">
        <div className="brand-symbol auth-symbol">N</div>
        <div className="eyebrow">NANOBIO ADMIN</div>
        <h1>Đăng nhập quản trị</h1>
        <p>Đăng nhập bằng tài khoản có quyền <strong>super_admin</strong>.</p>
        <form onSubmit={submit} className="form-stack">
          <label className="field-label">Tên đăng nhập, số điện thoại hoặc email
            <input name="identifier" autoComplete="username" required placeholder="nanobio" />
          </label>
          <label className="field-label">Mật khẩu
            <input name="password" autoComplete="current-password" type="password" required />
          </label>
          {error && <InlineError message={error} />}
          <button className="button button-primary button-wide" type="submit" disabled={busy}>{busy ? "Đang đăng nhập…" : "Đăng nhập"}</button>
        </form>
        <p className="auth-footnote">Phiên đăng nhập chỉ được lưu trong tab trình duyệt hiện tại.</p>
      </section>
    </main>
  );
}

function PasswordChangeScreen({ onSubmit }: { onSubmit: (password: string) => Promise<void> }) {
  const [error, setError] = useState("");
  const [busy, setBusy] = useState(false);
  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const form = new FormData(event.currentTarget);
    const password = String(form.get("password") ?? "");
    if (password.length < 8) return setError("Mật khẩu mới cần tối thiểu 8 ký tự.");
    if (password !== String(form.get("confirm") ?? "")) return setError("Hai mật khẩu chưa trùng nhau.");
    setBusy(true);
    setError("");
    try {
      await onSubmit(password);
    } catch (reason) {
      setError(getErrorMessage(reason));
    } finally {
      setBusy(false);
    }
  }
  return (
    <main className="auth-page">
      <section className="auth-card">
        <div className="brand-symbol auth-symbol">N</div>
        <div className="eyebrow">BẢO MẬT TÀI KHOẢN</div>
        <h1>Đổi mật khẩu tạm</h1>
        <p>Đặt mật khẩu mới trước khi tiếp tục vào khu vực quản trị.</p>
        <form onSubmit={submit} className="form-stack">
          <label className="field-label">Mật khẩu mới<input name="password" type="password" autoComplete="new-password" minLength={8} required /></label>
          <label className="field-label">Nhập lại mật khẩu<input name="confirm" type="password" autoComplete="new-password" minLength={8} required /></label>
          {error && <InlineError message={error} />}
          <button className="button button-primary button-wide" type="submit" disabled={busy}>{busy ? "Đang cập nhật…" : "Lưu mật khẩu mới"}</button>
        </form>
      </section>
    </main>
  );
}

function ReadinessBanner({ readiness, inline = false }: { readiness: Readiness | null; inline?: boolean }) {
  if (readiness?.ready) {
    return inline ? <div className="ready-strip"><span className="status-dot status-dot-ok" /> API và cơ sở dữ liệu sẵn sàng <time>{formatDate(readiness.checkedAt)}</time></div> : null;
  }
  return (
    <div className={`readiness-banner ${inline ? "readiness-inline" : ""}`} role="status">
      <span className="status-dot status-dot-error" />
      <div><strong>API chưa sẵn sàng</strong><span>{readiness?.message || "Đang kiểm tra trạng thái kết nối…"} Thao tác ghi đang bị khóa.</span></div>
      {readiness?.checkedAt && <time>{formatDate(readiness.checkedAt)}</time>}
    </div>
  );
}

function ScreenMessage({ title, readiness, notice, action }: { title: string; readiness: Readiness | null; notice?: Notice | null; action?: ReactNode }) {
  return <main className="auth-page"><div className="screen-message"><div className="brand-symbol">N</div><h1>{title}</h1>{readiness?.ready ? null : <ReadinessBanner readiness={readiness} />}{notice && <InlineError message={notice.text} />}{action}</div></main>;
}

function NoticeBanner({ notice, onDismiss }: { notice: Notice; onDismiss: () => void }) {
  return <div className={`notice notice-${notice.tone}`} role={notice.tone === "error" ? "alert" : "status"}><span>{notice.text}</span><button type="button" aria-label="Đóng thông báo" onClick={onDismiss}>×</button></div>;
}

function InlineError({ message }: { message: string }) {
  return <p className="inline-error" role="alert">{message}</p>;
}

function UserTable({ users, loading, query, onSelect }: {
  users: AdminUserSummary[];
  loading: boolean;
  query: string;
  onSelect: (user: AdminUserSummary) => void;
}) {
  if (loading && users.length === 0) return <div className="table-state">Đang tìm tài khoản…</div>;
  if (!loading && users.length === 0) return <div className="empty-state"><span aria-hidden="true">⌕</span><strong>{query ? "Không tìm thấy tài khoản" : "Chưa có dữ liệu tài khoản"}</strong><p>{query ? "Thử tên hoặc số điện thoại khác." : "Nhập thông tin vào ô tìm kiếm để bắt đầu."}</p></div>;
  return (
    <div className="table-scroll">
      <table className="users-table">
        <thead><tr><th>Tài khoản</th><th>Số điện thoại</th><th>Trạng thái</th><th>Gói</th><th>Ngày tạo</th><th><span className="visually-hidden">Mở hồ sơ</span></th></tr></thead>
        <tbody>
          {users.map((user) => (
            <tr key={user.id}>
              <td><button className="user-link" type="button" onClick={() => onSelect(user)}><span className="avatar-user">{user.title.slice(0, 1).toUpperCase()}</span><span><strong>{user.title}</strong><small>{user.email || user.subtitle || user.id}</small></span></button></td>
              <td className="phone-cell">{user.phone || "—"}</td>
              <td><StatusPill status={user.status} active={user.is_active} /></td>
              <td><PlanPill plan={user.plan_code} /></td>
              <td>{formatDate(user.created_at)}</td>
              <td><button className="icon-button open-user" type="button" onClick={() => onSelect(user)} aria-label={`Mở hồ sơ ${user.title}`}>›</button></td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

function StatusPill({ status, active }: { status: string; active: boolean }) {
  const value = status === "closed" ? "Đã đóng" : status === "suspended" ? "Tạm khóa" : active ? "Đang hoạt động" : "Không hoạt động";
  const tone = status === "closed" || !active ? "muted" : status === "suspended" ? "warning" : "success";
  return <span className={`pill pill-${tone}`}><span className="pill-dot" />{value}</span>;
}

function PlanPill({ plan }: { plan: string }) {
  const label = plan === "family_plus" ? "Family Plus" : plan === "plus" ? "Plus" : "Free";
  return <span className={`plan-pill ${plan === "free" ? "plan-free" : "plan-plus"}`}>{label}</span>;
}

function UserDrawer({ user, detail, section, data, loading, error, page, maxPages, ready, onClose, onChangeSection, onPage, onEdit, onIntent }: {
  user: AdminUserSummary;
  detail: Record<string, unknown>;
  section: UserDataSection;
  data: UserDataPage | null;
  loading: boolean;
  error: string;
  page: number;
  maxPages: number;
  ready: boolean;
  onClose: () => void;
  onChangeSection: (section: UserDataSection) => void;
  onPage: (page: number) => void;
  onEdit: () => void;
  onIntent: (intent: ActionIntent) => void;
}) {
  const drawerRef = useRef<HTMLElement | null>(null);
  const onCloseRef = useRef(onClose);
  useEffect(() => { onCloseRef.current = onClose; }, [onClose]);
  useEffect(() => {
    const previousFocus = document.activeElement instanceof HTMLElement ? document.activeElement : null;
    const focusTimer = window.requestAnimationFrame(() => {
      drawerRef.current?.querySelector<HTMLElement>("button")?.focus();
    });
    const onKey = (event: KeyboardEvent) => {
      if (event.key === "Escape") {
        onCloseRef.current();
        return;
      }
      if (event.key !== "Tab" || !drawerRef.current) return;
      const focusable = Array.from(drawerRef.current.querySelectorAll<HTMLElement>(
        'button:not([disabled]), input:not([disabled]), textarea:not([disabled]), select:not([disabled]), [tabindex]:not([tabindex="-1"])',
      ));
      if (focusable.length === 0) return;
      const first = focusable[0];
      const last = focusable[focusable.length - 1];
      if (event.shiftKey && document.activeElement === first) {
        event.preventDefault();
        last.focus();
      } else if (!event.shiftKey && document.activeElement === last) {
        event.preventDefault();
        first.focus();
      }
    };
    window.addEventListener("keydown", onKey);
    return () => {
      window.cancelAnimationFrame(focusTimer);
      window.removeEventListener("keydown", onKey);
      previousFocus?.focus();
    };
  }, []);
  const activeSection = SECTIONS.find((item) => item.id === section) ?? SECTIONS[0];
  const plusIsActive = Boolean(user.subscription_id && user.plan_code !== "free");
  const providerManaged = user.membership_source !== null && user.membership_source !== "manual";
  const closed = user.status === "closed" || !user.is_active;
  const canActivate = !user.is_active && user.status !== "closed";
  const joinedRows = Object.values(data?.tables ?? {}).reduce((sum, table) => sum + table.total, 0);
  return (
    <div className="drawer-backdrop" role="presentation" onMouseDown={(event) => { if (event.target === event.currentTarget) onClose(); }}>
      <section ref={drawerRef} className="user-drawer" role="dialog" aria-modal="true" aria-labelledby="drawer-title" tabIndex={-1}>
        <header className="drawer-header">
          <div><div className="breadcrumb">Người dùng <span>/</span> Hồ sơ chi tiết</div><h2 id="drawer-title">{user.title}</h2></div>
          <button className="icon-button drawer-close" type="button" onClick={onClose} aria-label="Đóng hồ sơ">×</button>
        </header>
        <div className="drawer-identity">
          <span className="avatar-user avatar-large">{user.title.slice(0, 1).toUpperCase()}</span>
          <div className="identity-main"><strong>{String(detail.phone || user.phone || "Chưa có số điện thoại")}</strong><span>{String(detail.email || user.email || "Chưa có email")}</span><div className="identity-pills"><StatusPill status={user.status} active={user.is_active} /><PlanPill plan={user.plan_code} /></div></div>
          <button className="button button-secondary button-small" type="button" disabled={!ready || closed} onClick={onEdit}>Chỉnh sửa hồ sơ</button>
        </div>

        <div className="drawer-actions" aria-label="Thao tác tài khoản">
          {canActivate && <button type="button" className="button button-primary button-small" disabled={!ready} onClick={() => onIntent({ kind: "activate" })}>✓ Kích hoạt tài khoản</button>}
          <button type="button" className="button button-secondary button-small" disabled={!ready || closed} onClick={() => onIntent({ kind: "reset" })}>↻ Đặt lại mật khẩu</button>
          {!plusIsActive ? (
            <button type="button" className="button button-accent button-small" disabled={!ready || closed} onClick={() => onIntent({ kind: "grant" })}>◇ Cấp Plus</button>
          ) : (
            <>
              <button type="button" className="button button-accent button-small" disabled={!ready || closed || providerManaged || !user.membership_ends_at} onClick={() => user.subscription_id && user.membership_ends_at && onIntent({ kind: "extend", subscriptionId: user.subscription_id, expectedEnd: user.membership_ends_at })}>Gia hạn Plus</button>
              <button type="button" className="button button-danger-quiet button-small" disabled={!ready || closed} onClick={() => user.subscription_id && onIntent({ kind: "revoke", subscriptionId: user.subscription_id, providerManaged })}>Kết thúc Plus</button>
            </>
          )}
          <button type="button" className="button button-danger-quiet button-small" disabled={!ready || closed} onClick={() => onIntent({ kind: "close" })}>Đóng tài khoản</button>
        </div>
        {plusIsActive && providerManaged && <p className="provider-note">Gói này do nhà cung cấp thanh toán quản lý. Kết thúc Plus ở đây chỉ thu hồi quyền trong NanoBio, không dừng gia hạn thanh toán bên ngoài.</p>}
        {plusIsActive && !providerManaged && !user.membership_ends_at && <p className="provider-note">Gói thủ công không có ngày kết thúc; hiện chưa thể gia hạn theo số ngày.</p>}

        <div className="section-heading"><div><h3>Dữ liệu tài khoản</h3><p>Đã ghi lý do truy cập · {joinedRows} bản ghi trong nhóm đang mở</p></div></div>
        <nav className="section-tabs" aria-label="Nhóm dữ liệu người dùng">
          {SECTIONS.map((item) => <button type="button" aria-current={section === item.id ? "page" : undefined} className={section === item.id ? "section-tab section-tab-active" : "section-tab"} key={item.id} onClick={() => onChangeSection(item.id)}><span aria-hidden="true">{item.icon}</span>{item.label}</button>)}
        </nav>
        {section === "profile" && <ProfileOverview user={detail} />}
        <div className="data-heading"><div><h4>{activeSection.label}</h4><span>{loading ? "Đang tải dữ liệu…" : `${joinedRows} bản ghi`}</span></div></div>
        {loading && <div className="table-state">Đang tải nhóm dữ liệu…</div>}
        {error && <InlineError message={error} />}
        {!loading && !error && data && <UserDataTables tables={data.tables} />}
        {!loading && !error && data && maxPages > 1 && (
          <div className="pagination"><span>Trang {page} / {maxPages}</span><div><button className="button button-secondary button-small" disabled={page <= 1} onClick={() => onPage(page - 1)}>Trước</button><button className="button button-secondary button-small" disabled={page >= maxPages} onClick={() => onPage(page + 1)}>Tiếp</button></div></div>
        )}
        <p className="drawer-disclaimer"><span>ⓘ</span> Dữ liệu sức khỏe chỉ xem trong màn hình này. Mật khẩu, token, provider secret và đường dẫn tệp không được trả về.</p>
      </section>
    </div>
  );
}

function ProfileOverview({ user }: { user: Record<string, unknown> }) {
  const fields: Array<[string, string]> = [
    ["ID tài khoản", "id"], ["Tên đăng nhập", "username"], ["Ảnh đại diện", "avatar_url"],
    ["Giới tính", "gender"], ["Năm sinh", "birth_year"], ["Quyền quản trị", "admin_roles"],
    ["Trạng thái tài khoản", "admin_status"], ["Đang hoạt động", "is_active"],
    ["Bắt buộc đổi mật khẩu", "force_password_change"], ["Chế độ ứng dụng", "app_access_mode"],
    ["Trạng thái onboarding", "onboarding_status"], ["Hoàn tất onboarding", "onboarding_completed_at"],
    ["Sale", "sale_status"], ["Tạo lúc", "created_at"], ["Cập nhật lúc", "updated_at"],
  ];
  return <div className="profile-grid">{fields.map(([label, key]) => <div className="profile-field" key={key}><span>{label}</span><strong>{key.endsWith("_at") ? formatDate(user[key]) : asText(user[key])}</strong></div>)}</div>;
}

function UserDataTables({ tables }: { tables: UserDataPage["tables"] }) {
  const entries = Object.entries(tables).filter(([, value]) => value.total > 0 || value.rows.length > 0);
  if (entries.length === 0) return <div className="empty-state data-empty"><span aria-hidden="true">◌</span><strong>Chưa có bản ghi trong nhóm này</strong><p>Không có dữ liệu đã lưu cho nhóm được chọn.</p></div>;
  return <div className="data-tables">{entries.map(([name, table]) => {
    const columns = Array.from(new Set(table.rows.flatMap((row) => Object.keys(row))));
    return (
      <section className="data-table-card" key={name}>
        <header><strong>{humanize(name)}</strong><span>{table.total} bản ghi</span></header>
        {table.rows.length === 0 ? <p className="table-empty">Không có bản ghi ở trang này.</p> : (
          <div className="record-list">
            {table.rows.map((row, index) => (
              <article className="record-card" key={String(row.id ?? row.request_id ?? `${name}-${index}`)}>
                {columns.map((column) => <div className="record-field" key={column}><span>{humanize(column)}</span><strong>{asText(row[column])}</strong></div>)}
              </article>
            ))}
          </div>
        )}
      </section>
    );
  })}</div>;
}

function humanize(value: string): string {
  const known: Record<string, string> = {
    mobile_profile: "Hồ sơ đồng bộ từ ứng dụng",
    membership_subscriptions: "Gói thành viên",
    usage_quota_counters: "Hạn mức sử dụng",
    usage_events: "Lượt sử dụng",
    payment_requests: "Yêu cầu thanh toán",
    manual_payment_events: "Thanh toán chuyển khoản",
    payment_events: "Giao dịch thanh toán",
    google_play_purchases: "Giao dịch Google Play",
    health_subjects: "Hồ sơ sức khỏe",
    family_groups: "Nhóm gia đình",
    family_members: "Thành viên gia đình",
    sleep_safety_contacts: "Liên hệ an toàn",
    sleep_safety_preferences: "Cài đặt giấc ngủ",
    sleep_safety_sessions: "Phiên giám sát giấc ngủ",
    sleep_safety_events: "Sự kiện giấc ngủ",
    sleep_safety_dispatches: "Thông báo an toàn",
    sale_profiles: "Hồ sơ Sale",
    sale_payout_profiles: "Thông tin nhận thanh toán",
    commission_records: "Hoa hồng",
    wellness_reward_wallets: "Ví điểm thưởng",
    wellness_point_ledgers: "Lịch sử điểm",
    wellness_point_allocations: "Phân bổ điểm",
    wellness_reward_redemptions: "Đổi thưởng",
    refresh_sessions: "Phiên đăng nhập",
    admin_audit_events: "Audit tài khoản",
    domain_records: "Dữ liệu nghiệp vụ",
    ai_content_reports: "Báo cáo nội dung AI",
    file_objects: "Tệp đã lưu",
  };
  return known[value] || value.replaceAll("_", " ").replace(/\b\w/g, (letter) => letter.toUpperCase());
}

function ReasonModal({ title, description, reason, busy, error, confirmLabel, onReasonChange, onClose, onSubmit }: {
  title: string;
  description: string;
  reason: string;
  busy: boolean;
  error: string;
  confirmLabel: string;
  onReasonChange: (value: string) => void;
  onClose: () => void;
  onSubmit: (event: FormEvent<HTMLFormElement>) => void;
}) {
  return <ModalShell title={title} onClose={onClose}><form className="form-stack" onSubmit={onSubmit}><p className="modal-copy">{description}</p><label className="field-label">Lý do truy cập<textarea value={reason} onChange={(event) => onReasonChange(event.target.value)} minLength={2} maxLength={500} rows={3} required autoFocus placeholder="Ví dụ: hỗ trợ yêu cầu cập nhật hồ sơ…" /></label>{error && <InlineError message={error} />}<div className="modal-actions"><button className="button button-secondary" type="button" onClick={onClose}>Hủy</button><button className="button button-primary" disabled={busy || reason.trim().length < 2}>{busy ? "Đang mở…" : confirmLabel}</button></div></form></ModalShell>;
}

function ActionModal({ intent, userName, ready, onClose, onConfirm }: {
  intent: ActionIntent;
  userName: string;
  ready: boolean;
  onClose: () => void;
  onConfirm: (reason: string, days: number) => Promise<void>;
}) {
  const [reason, setReason] = useState("");
  const [days, setDays] = useState(30);
  const [busy, setBusy] = useState(false);
  const actionTitles: Record<ActionIntent["kind"], string> = {
    activate: "Kích hoạt tài khoản",
    close: "Đóng tài khoản",
    reset: "Đặt lại mật khẩu",
    grant: "Cấp gói Plus",
    extend: "Gia hạn gói Plus",
    revoke: "Kết thúc gói Plus",
  };
  const descriptions: Record<ActionIntent["kind"], string> = {
    activate: "Tài khoản sẽ được chuyển sang trạng thái hoạt động để người dùng có thể đăng nhập. Lý do kích hoạt sẽ được lưu trong audit.",
    close: "Tài khoản sẽ chuyển sang trạng thái đóng và mọi phiên đăng nhập sẽ bị thu hồi. Dữ liệu và audit được giữ lại.",
    reset: "Máy chủ sẽ tạo mật khẩu tạm riêng, thu hồi phiên hiện tại và buộc người dùng đổi mật khẩu khi đăng nhập.",
    grant: "Gói Plus được cấp thủ công và mặc định bắt đầu ngay. Tài khoản không được đổi sang gói provider.",
    extend: "Số ngày sẽ được cộng vào ngày kết thúc hiện tại của gói quản lý thủ công.",
    revoke: intent.kind === "revoke" && intent.providerManaged
      ? "Quyền Plus trong NanoBio sẽ dừng ngay. Gia hạn thanh toán do nhà cung cấp quản lý không bị hủy."
      : "Quyền Plus trong NanoBio sẽ dừng ngay. Thao tác này không hoàn tiền.",
  };
  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (reason.trim().length < 2 || !ready) return;
    setBusy(true);
    try {
      await onConfirm(reason.trim(), days);
    } finally {
      setBusy(false);
    }
  }
  return <ModalShell title={actionTitles[intent.kind]} onClose={onClose} danger={intent.kind === "close" || intent.kind === "revoke"}><form className="form-stack" onSubmit={submit}><p className="modal-copy">{descriptions[intent.kind]} <strong>{userName}</strong></p>{(intent.kind === "grant" || intent.kind === "extend") && <label className="field-label">Số ngày<input type="number" min={1} max={3650} value={days} onChange={(event) => setDays(Number(event.target.value))} required /></label>}<label className="field-label">Lý do thao tác<textarea value={reason} onChange={(event) => setReason(event.target.value)} rows={3} minLength={2} maxLength={500} required autoFocus placeholder="Nhập lý do để lưu audit…" /></label>{!ready && <InlineError message="API chưa sẵn sàng. Thao tác ghi đang bị khóa." />}<div className="modal-actions"><button className="button button-secondary" type="button" onClick={onClose}>Hủy</button><button className={intent.kind === "close" || intent.kind === "revoke" ? "button button-danger" : "button button-primary"} disabled={busy || !ready || reason.trim().length < 2}>{busy ? "Đang lưu…" : "Xác nhận"}</button></div></form></ModalShell>;
}

function EditProfileModal({ user, ready, onClose, onSubmit }: {
  user: Record<string, unknown>;
  ready: boolean;
  onClose: () => void;
  onSubmit: (event: FormEvent<HTMLFormElement>) => void;
}) {
  return <ModalShell title="Chỉnh sửa hồ sơ" onClose={onClose}><form className="form-stack" onSubmit={onSubmit}>
    <label className="field-label">Họ và tên<input name="full_name" minLength={2} maxLength={120} defaultValue={String(user.full_name ?? "")} required /></label>
    <div className="form-row"><label className="field-label">Số điện thoại<input name="phone" inputMode="tel" defaultValue={String(user.phone ?? "")} /></label><label className="field-label">Email<input name="email" type="email" defaultValue={String(user.email ?? "")} /></label></div>
    <div className="form-row"><label className="field-label">Giới tính<select name="gender" defaultValue={String(user.gender ?? "")}><option value="">Chưa cung cấp</option><option value="male">Nam</option><option value="female">Nữ</option><option value="other">Khác</option><option value="prefer_not_to_say">Không muốn nêu</option></select></label><label className="field-label">Năm sinh<input name="birth_year" type="number" min={1900} max={2100} defaultValue={user.birth_year ? String(user.birth_year) : ""} /></label></div>
    <label className="field-label">Lý do cập nhật<textarea name="reason" minLength={2} maxLength={500} rows={2} required /></label>
    <p className="modal-copy">Thông tin sức khỏe chỉ xem và không chỉnh sửa tại đây.</p>
    {!ready && <InlineError message="API chưa sẵn sàng. Thao tác ghi đang bị khóa." />}
    <div className="modal-actions"><button className="button button-secondary" type="button" onClick={onClose}>Hủy</button><button className="button button-primary" disabled={!ready}>Lưu thay đổi</button></div>
  </form></ModalShell>;
}

type CreateResult = { name: string; phone: string; password?: string; error?: string };
function CreateAccountsModal({ ready, onClose, onCreate }: {
  ready: boolean;
  onClose: () => void;
  onCreate: (rows: Array<{ phone: string; full_name: string; email?: string }>, reason: string) => Promise<CreateResult[]>;
}) {
  const [rawRows, setRawRows] = useState("");
  const [reason, setReason] = useState("");
  const [results, setResults] = useState<CreateResult[] | null>(null);
  const [error, setError] = useState("");
  const [busy, setBusy] = useState(false);
  const successful = results?.filter((result) => !result.error) ?? [];
  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const rows = rawRows.split(/\r?\n/).map((line) => line.trim()).filter(Boolean).map((line) => {
      const [phone, full_name, email] = line.split("|").map((part) => part.trim());
      return { phone: phone ?? "", full_name: full_name ?? "", ...(email ? { email } : {}) };
    });
    if (rows.length < 1 || rows.length > 100) return setError("Nhập từ 1 đến 100 dòng tài khoản.");
    if (rows.some((row) => !row.phone || row.full_name.length < 2)) return setError("Mỗi dòng cần có số điện thoại và họ tên.");
    setBusy(true);
    setError("");
    try {
      setResults(await onCreate(rows, reason.trim()));
    } catch (reasonError) {
      setError(getErrorMessage(reasonError));
    } finally {
      setBusy(false);
    }
  }
  return <ModalShell title={results ? "Kết quả tạo tài khoản" : "Tạo tài khoản"} onClose={onClose} wide>
    {results ? <div className="form-stack">
      <p className="modal-copy">Đã xử lý tuần tự {results.length} dòng. Mật khẩu tạm chỉ xuất hiện một lần trong phiên này.</p>
      <div className="creation-results">{results.map((result, index) => <div className="creation-result" key={`${result.phone}-${index}`}><span className={result.error ? "result-mark result-fail" : "result-mark result-ok"}>{result.error ? "!" : "✓"}</span><div className="creation-result-main"><strong>{result.name || result.phone}</strong><span>{result.phone}</span>{result.password && <code>{result.password}</code>}{result.error && <small>{result.error}</small>}</div>{result.password && <button type="button" className="button button-secondary button-small" onClick={() => void navigator.clipboard?.writeText(result.password!)}>Sao chép</button>}</div>)}</div>
      <p className="result-summary">{successful.length} thành công · {results.length - successful.length} thất bại</p>
      <div className="modal-actions"><button className="button button-primary" type="button" onClick={onClose}>Đóng và xóa mật khẩu tạm khỏi màn hình</button></div>
    </div> : <form className="form-stack" onSubmit={submit}>
      <p className="modal-copy">Tài khoản mới được tạo ở gói Free. Mỗi dòng theo định dạng <code>SĐT | Họ tên | email</code>; email có thể bỏ trống.</p>
      <label className="field-label">Danh sách tài khoản<textarea value={rawRows} onChange={(event) => setRawRows(event.target.value)} rows={7} required autoFocus placeholder={"0912345678 | Nguyễn An | an@example.com\n0987654321 | Trần Bình"} /></label>
      <label className="field-label">Lý do tạo tài khoản<textarea value={reason} onChange={(event) => setReason(event.target.value)} rows={2} minLength={2} maxLength={500} required placeholder="Ví dụ: tạo theo yêu cầu hỗ trợ…" /></label>
      {error && <InlineError message={error} />}
      {!ready && <InlineError message="API chưa sẵn sàng. Thao tác ghi đang bị khóa." />}
      <div className="modal-actions"><button className="button button-secondary" type="button" onClick={onClose}>Hủy</button><button className="button button-primary" disabled={!ready || busy}>{busy ? "Đang tạo từng tài khoản…" : "Tạo tài khoản"}</button></div>
    </form>}
  </ModalShell>;
}

function TemporaryPasswordModal({ label, password, onClose }: { label: string; password: string; onClose: () => void }) {
  const [copied, setCopied] = useState(false);
  async function copy() {
    try {
      await navigator.clipboard.writeText(password);
      setCopied(true);
    } catch {
      setCopied(false);
    }
  }
  return <ModalShell title="Mật khẩu tạm — chỉ xem một lần" onClose={onClose}><div className="form-stack"><p className="modal-copy">{label}. Người dùng sẽ phải đổi mật khẩu ngay lần đăng nhập tiếp theo.</p><code className="temporary-password">{password}</code><div className="modal-actions"><button className="button button-secondary" type="button" onClick={() => void copy()}>{copied ? "Đã sao chép" : "Sao chép mật khẩu"}</button><button className="button button-primary" type="button" onClick={onClose}>Đã lưu, đóng lại</button></div><p className="one-time-note">Đóng cửa sổ sẽ xóa mật khẩu khỏi giao diện. Có thể đặt lại mật khẩu mới nếu bị mất.</p></div></ModalShell>;
}

function ModalShell({ title, children, onClose, danger = false, wide = false }: {
  title: string;
  children: ReactNode;
  onClose: () => void;
  danger?: boolean;
  wide?: boolean;
}) {
  const dialogRef = useRef<HTMLElement | null>(null);
  const onCloseRef = useRef(onClose);
  useEffect(() => { onCloseRef.current = onClose; }, [onClose]);
  useEffect(() => {
    const previousFocus = document.activeElement instanceof HTMLElement ? document.activeElement : null;
    const focusTimer = window.requestAnimationFrame(() => {
      dialogRef.current?.querySelector<HTMLElement>("input, textarea, select, button")?.focus();
    });
    const onKey = (event: KeyboardEvent) => {
      if (event.key === "Escape") {
        onCloseRef.current();
        return;
      }
      if (event.key !== "Tab" || !dialogRef.current) return;
      const focusable = Array.from(dialogRef.current.querySelectorAll<HTMLElement>(
        'button:not([disabled]), input:not([disabled]), textarea:not([disabled]), select:not([disabled]), [tabindex]:not([tabindex="-1"])',
      ));
      if (focusable.length === 0) return;
      const first = focusable[0];
      const last = focusable[focusable.length - 1];
      if (event.shiftKey && document.activeElement === first) {
        event.preventDefault();
        last.focus();
      } else if (!event.shiftKey && document.activeElement === last) {
        event.preventDefault();
        first.focus();
      }
    };
    window.addEventListener("keydown", onKey);
    return () => {
      window.cancelAnimationFrame(focusTimer);
      window.removeEventListener("keydown", onKey);
      previousFocus?.focus();
    };
  }, []);
  return <div className="modal-backdrop" role="presentation" onMouseDown={(event) => { if (event.target === event.currentTarget) onClose(); }}><section ref={dialogRef} className={`modal-card ${wide ? "modal-wide" : ""}`} role="dialog" aria-modal="true" aria-labelledby="modal-title" tabIndex={-1}><header className={danger ? "modal-header modal-header-danger" : "modal-header"}><h2 id="modal-title">{title}</h2><button type="button" className="icon-button" aria-label="Đóng" onClick={onClose}>×</button></header><div className="modal-body">{children}</div></section></div>;
}
