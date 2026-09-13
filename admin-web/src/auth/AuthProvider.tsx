import { createContext, useCallback, useContext, useEffect, useMemo, useState, type ReactNode } from 'react';
import type { Session } from '@supabase/supabase-js';
import { AdminApi, AdminApiError } from '../lib/admin-api';
import type { AdminSession } from '../types';

type AuthStatus = 'loading' | 'signed_out' | 'signed_in' | 'forbidden' | 'error';

type AuthContextValue = {
  api: AdminApi;
  status: AuthStatus;
  session: AdminSession | null;
  userEmail: string | null;
  message: string | null;
  signIn: (email: string, password: string) => Promise<void>;
  signOut: () => Promise<void>;
  refresh: () => Promise<void>;
};

const AuthContext = createContext<AuthContextValue | null>(null);

export function AuthProvider({ children }: { children: ReactNode }) {
  const api = useMemo(() => new AdminApi(), []);
  const [status, setStatus] = useState<AuthStatus>('loading');
  const [session, setSession] = useState<AdminSession | null>(null);
  const [userEmail, setUserEmail] = useState<string | null>(null);
  const [message, setMessage] = useState<string | null>(null);

  const loadFromSession = useCallback(async (authSession: Session | null, signOutNonAdmin = true, throwOnError = false): Promise<AdminSession | null> => {
    if (!authSession) {
      setSession(null);
      setUserEmail(null);
      setStatus('signed_out');
      return null;
    }

    setUserEmail(authSession.user.email ?? null);
    try {
      const adminSession = await api.fetchAdminSession();
      if (!adminSession.active || adminSession.roles.length === 0) {
        if (signOutNonAdmin) await api.signOut().catch(() => undefined);
        setSession(null);
        setStatus('forbidden');
        setMessage('Tài khoản này chưa có quyền quản trị đang hoạt động.');
        return null;
      }
      setSession(adminSession);
      setStatus('signed_in');
      setMessage(null);
      return adminSession;
    } catch (error) {
      setSession(null);
      setStatus('error');
      setMessage(error instanceof Error ? error.message : 'Chưa thể kiểm tra quyền quản trị.');
      if (throwOnError) throw error;
      return null;
    }
  }, [api]);

  const refresh = useCallback(async () => {
    setStatus('loading');
    try {
      const current = await api.getCurrentSession();
      await loadFromSession(current);
    } catch (error) {
      setStatus('error');
      setMessage(error instanceof Error ? error.message : 'Chưa thể kết nối khu quản trị.');
    }
  }, [api, loadFromSession]);

  useEffect(() => {
    void refresh();
    let subscription: { unsubscribe: () => void } | undefined;
    try {
      subscription = api.watchAuth((_event, authSession) => {
        void loadFromSession(authSession, false);
      });
    } catch (error) {
      setStatus('error');
      setMessage(error instanceof Error ? error.message : 'Chưa thể khởi động khu quản trị.');
    }
    return () => subscription?.unsubscribe();
  }, [api, loadFromSession, refresh]);

  const signIn = useCallback(async (email: string, password: string) => {
    setStatus('loading');
    setMessage(null);
    try {
      await api.signIn(email, password);
      const current = await api.getCurrentSession();
      const next = await loadFromSession(current, true, true);
      if (!next) {
        throw new AdminApiError('Tài khoản này chưa có quyền quản trị đang hoạt động.');
      }
    } catch (error) {
      const safeMessage = error instanceof Error ? error.message : 'Chưa thể đăng nhập lúc này.';
      if (safeMessage.includes('chưa có quyền quản trị')) {
        setStatus('forbidden');
      } else {
        setStatus('error');
      }
      setMessage(safeMessage);
      throw error;
    }
  }, [api, loadFromSession]);

  const signOut = useCallback(async () => {
    await api.signOut();
    setSession(null);
    setUserEmail(null);
    setStatus('signed_out');
    setMessage(null);
  }, [api]);

  return (
    <AuthContext.Provider value={{ api, status, session, userEmail, message, signIn, signOut, refresh }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAdminAuth(): AuthContextValue {
  const context = useContext(AuthContext);
  if (!context) throw new Error('useAdminAuth must be used inside AuthProvider');
  return context;
}
