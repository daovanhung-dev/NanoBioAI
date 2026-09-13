import { useState, type ReactNode } from 'react';
import { NavLink, useLocation, useNavigate } from 'react-router-dom';
import {
  BadgeDollarSign,
  BarChart3,
  ClipboardCheck,
  FileCheck2,
  FileCog,
  Gauge,
  History,
  LayoutDashboard,
  LogOut,
  Menu,
  RefreshCw,
  Settings2,
  ShieldCheck,
  Sparkles,
  Users,
  WalletCards,
  X,
} from 'lucide-react';
import { useAdminAuth } from '../auth/AuthProvider';
import { SECTION_CONFIG, SECTIONS, canAccessSection, type AdminSection } from '../types';

const icons: Record<AdminSection, typeof Gauge> = {
  dashboard: LayoutDashboard,
  users: Users,
  payments: WalletCards,
  sales: BadgeDollarSign,
  'sale-conversions': BarChart3,
  'wellness-rewards': Sparkles,
  reconciliation: ClipboardCheck,
  plans: ShieldCheck,
  reports: FileCheck2,
  audit: History,
  config: Settings2,
};

const roleLabels: Record<string, string> = {
  super_admin: 'Super Admin',
  finance_admin: 'Finance Admin',
  support_admin: 'Support Admin',
  content_admin: 'Content Admin',
  operations_admin: 'Operations Admin',
};

export function AdminShell({ children }: { children: ReactNode }) {
  const { session, userEmail, signOut, refresh } = useAdminAuth();
  const navigate = useNavigate();
  const location = useLocation();
  const [mobileOpen, setMobileOpen] = useState(false);
  if (!session) return <>{children}</>;

  const sections = SECTIONS.filter((section) => canAccessSection(session, section));
  const currentSection = sectionFromPath(location.pathname);
  const grouped = sections.reduce<Record<string, AdminSection[]>>((groups, section) => {
    const group = SECTION_CONFIG[section].group;
    (groups[group] ??= []).push(section);
    return groups;
  }, {});

  async function handleSignOut() {
    await signOut().catch(() => undefined);
    navigate('/admin/login', { replace: true });
  }

  function refreshPage() {
    void refresh();
    window.dispatchEvent(new CustomEvent('admin:refresh'));
  }

  return (
    <div className="app-shell">
      <aside className={`sidebar ${mobileOpen ? 'sidebar-open' : ''}`}>
        <div className="brand-block">
          <div className="brand-mark"><ShieldCheck size={22} /></div>
          <div><strong>NanoBio Admin</strong><span>Vận hành an toàn</span></div>
          {mobileOpen && <button className="icon-button mobile-close" aria-label="Đóng menu" onClick={() => setMobileOpen(false)}><X size={19} /></button>}
        </div>
        <nav aria-label="Điều hướng Admin">
          {Object.entries(grouped).map(([group, items]) => (
            <div className="nav-group" key={group}>
              <span className="nav-group-title">{group}</span>
              {items.map((section) => {
                const Icon = icons[section];
                return (
                  <NavLink key={section} to={`/admin/${section}`} className={({ isActive }) => `nav-link ${isActive || (section === 'dashboard' && currentSection === 'dashboard') ? 'active' : ''}`} onClick={() => setMobileOpen(false)}>
                    <Icon size={18} aria-hidden="true" /><span>{SECTION_CONFIG[section].label}</span>
                  </NavLink>
                );
              })}
            </div>
          ))}
        </nav>
        <div className="sidebar-footer">
          <span className="safe-note"><span className="online-dot" /> Phiên quản trị đang hoạt động</span>
          <button className="sidebar-signout" onClick={() => void handleSignOut()}><LogOut size={16} /> Đăng xuất</button>
        </div>
      </aside>

      {mobileOpen && <button className="mobile-overlay" aria-label="Đóng menu" onClick={() => setMobileOpen(false)} />}
      <main className="main-area">
        <header className="topbar">
          <div className="topbar-leading">
            <button className="icon-button mobile-menu" aria-label="Mở menu" onClick={() => setMobileOpen(true)}><Menu size={21} /></button>
            <div><span className="eyebrow">NanoBio / Admin</span><strong>{SECTION_CONFIG[currentSection].label}</strong></div>
          </div>
          <div className="topbar-actions">
            <button className="icon-button" aria-label="Tải lại dữ liệu" title="Tải lại dữ liệu" onClick={refreshPage}><RefreshCw size={18} /></button>
            <div className="profile-chip"><span className="avatar">{(userEmail?.[0] ?? 'A').toUpperCase()}</span><span className="profile-copy"><strong>{userEmail ?? 'Admin'}</strong><small>{session.roles.map((role) => roleLabels[role] ?? role).join(' · ')}</small></span></div>
          </div>
        </header>
        <div className="content-wrap">{children}</div>
      </main>
    </div>
  );
}

function sectionFromPath(path: string): AdminSection {
  const segment = path.split('/').filter(Boolean).at(-1);
  if (segment && segment in SECTION_CONFIG) return segment as AdminSection;
  if (path.includes('memberships') || path.includes('payments')) return 'payments';
  if (path.includes('sales')) return path.includes('payout') ? 'sale-conversions' : 'sales';
  if (path.includes('accounts')) return 'users';
  return 'dashboard';
}
