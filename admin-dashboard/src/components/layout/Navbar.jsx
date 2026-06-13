import React, { useState, useMemo } from 'react';
import { Link, useNavigate, useLocation } from 'react-router-dom';
import { useAuth } from '../../hooks/useAuth';
import { useNotifications } from '../../hooks/useNotifications';
import { useTheme } from '../../context/ThemeContext';
import { getNavSections } from './Sidebar';
import { useRoleAccess } from '../../hooks/useRoleAccess';
import ConfirmDialog from '../shared/ConfirmDialog';

const formatTime = (dateStr) => {
  const diff = Date.now() - new Date(dateStr).getTime();
  const mins = Math.floor(diff / 60000);
  if (mins < 1) return 'Baru saja';
  if (mins < 60) return `${mins}m lalu`;
  const hrs = Math.floor(diff / 3600000);
  if (hrs < 24) return `${hrs}j lalu`;
  const days = Math.floor(diff / 86400000);
  if (days < 7) return `${days}h lalu`;
  return new Date(dateStr).toLocaleDateString('id-ID', { day: 'numeric', month: 'short' });
};

const getTypeStyle = (type) => {
  switch (type) {
    case 'success': return { icon: 'check_circle', color: 'text-emerald-600 dark:text-emerald-400 bg-emerald-50 dark:bg-emerald-900/20' };
    case 'error': return { icon: 'error', color: 'text-red-500 dark:text-red-400 bg-red-50 dark:bg-red-900/20' };
    case 'warning': return { icon: 'warning', color: 'text-orange-500 dark:text-orange-400 bg-orange-50 dark:bg-orange-900/20' };
    default: return { icon: 'info', color: 'text-blue-600 dark:text-blue-400 bg-blue-50 dark:bg-blue-900/20' };
  }
};

const Navbar = () => {
  const { profile, signOut } = useAuth();
  const { notifications, unreadCount, markAsRead, markAllAsRead } = useNotifications();
  const { isDark, toggleTheme } = useTheme();
  const { roleLabel, isDirektur } = useRoleAccess();
  const location = useLocation();
  const navigate = useNavigate();
  const [showProfile, setShowProfile] = useState(false);
  const [showNotif, setShowNotif] = useState(false);
  const [showLogoutConfirm, setShowLogoutConfirm] = useState(false);

  // Title diambil dari label sidebar (sesuai permintaan: header = label sidebar)
  const headerTitle = useMemo(() => {
    const navSections = getNavSections(isDirektur);
    for (const section of navSections) {
      const item = section.items.find((i) =>
        i.path === '/dashboard'
          ? location.pathname === '/dashboard'
          : location.pathname.startsWith(i.path)
      );
      if (item) return item.label;
    }
    return 'Dashboard';
  }, [location.pathname, isDirektur]);

  const handleNotifClick = (n) => {
    if (!n.is_read) markAsRead(n.id);
    setShowNotif(false);
    if (n.metadata?.request_id) {
      navigate('/dashboard/pengajuan-cukai');
    } else {
      navigate('/dashboard/notifikasi');
    }
  };

  const recentNotifs = notifications.slice(0, 5);

  return (
    <>
      <header className="bg-white dark:bg-gray-900 border-b border-gray-200 dark:border-gray-800 sticky top-0 z-30">
        <div className="flex justify-between items-center w-full px-6 py-3">
          {/* Left: Header title (sesuai label sidebar) */}
          <div className="min-w-0">
            <h1 className="text-lg font-bold text-gray-900 dark:text-white truncate">{headerTitle}</h1>
          </div>

          {/* Right: Actions */}
          <div className="flex items-center gap-2">
            {/* Theme Toggle */}
            <button
              onClick={toggleTheme}
              className="w-9 h-9 flex items-center justify-center text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-white hover:bg-gray-100 dark:hover:bg-gray-800 rounded-lg transition-colors"
              title={isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode'}
              aria-label="Toggle theme"
            >
              <span className="material-symbols-outlined text-[22px]">{isDark ? 'light_mode' : 'dark_mode'}</span>
            </button>

            {/* Notifications */}
            <div className="relative">
              <button
                onClick={() => { setShowNotif((v) => !v); setShowProfile(false); }}
                className="relative w-9 h-9 flex items-center justify-center text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-white hover:bg-gray-100 dark:hover:bg-gray-800 rounded-lg transition-colors"
                aria-label="Notifikasi"
              >
                <span className="material-symbols-outlined text-[22px]">notifications</span>
                {unreadCount > 0 && (
                  <span className="absolute -top-0.5 -right-0.5 min-w-[18px] h-[18px] px-1 bg-red-500 text-white text-[10px] font-bold rounded-full flex items-center justify-center ring-2 ring-white dark:ring-gray-900">
                    {unreadCount > 99 ? '99+' : unreadCount}
                  </span>
                )}
              </button>

              {showNotif && (
                <>
                  <div className="fixed inset-0 z-40" onClick={() => setShowNotif(false)}></div>
                  <div className="absolute right-0 top-full mt-2 w-[360px] bg-white dark:bg-gray-900 border border-gray-200 dark:border-gray-800 rounded-xl shadow-xl z-50 overflow-hidden animate-[slideDown_140ms_ease-out]">
                    <div className="px-4 py-3 border-b border-gray-100 dark:border-gray-800 flex items-center justify-between">
                      <div>
                        <h3 className="text-sm font-bold text-gray-900 dark:text-white">Notifikasi</h3>
                        <p className="text-[11px] text-gray-400 dark:text-gray-500">{unreadCount} belum dibaca</p>
                      </div>
                      {unreadCount > 0 && (
                        <button
                          onClick={() => markAllAsRead()}
                          className="text-[11px] font-semibold text-blue-600 dark:text-blue-400 hover:text-blue-700"
                        >
                          Baca Semua
                        </button>
                      )}
                    </div>

                    <div className="max-h-[360px] overflow-y-auto custom-scrollbar divide-y divide-gray-50 dark:divide-gray-800">
                      {recentNotifs.length === 0 ? (
                        <div className="px-4 py-10 text-center">
                          <span className="material-symbols-outlined text-gray-300 dark:text-gray-600 text-[32px]">notifications_off</span>
                          <p className="text-xs text-gray-500 dark:text-gray-400 mt-2">Belum ada notifikasi</p>
                        </div>
                      ) : (
                        recentNotifs.map((n) => {
                          const s = getTypeStyle(n.type);
                          return (
                            <button
                              key={n.id}
                              onClick={() => handleNotifClick(n)}
                              className={`w-full text-left px-4 py-3 flex items-start gap-3 hover:bg-gray-50 dark:hover:bg-gray-800/50 transition-colors ${!n.is_read ? 'bg-blue-50/40 dark:bg-blue-900/10' : ''}`}
                            >
                              <div className={`w-8 h-8 rounded-lg flex items-center justify-center shrink-0 ${s.color}`}>
                                <span className="material-symbols-outlined text-[16px]">{n.icon || s.icon}</span>
                              </div>
                              <div className="flex-1 min-w-0">
                                <div className="flex items-start justify-between gap-2">
                                  <p className={`text-[13px] truncate ${!n.is_read ? 'font-bold text-gray-900 dark:text-white' : 'font-medium text-gray-700 dark:text-gray-300'}`}>{n.title}</p>
                                  {!n.is_read && <span className="w-1.5 h-1.5 rounded-full bg-blue-600 shrink-0 mt-1.5"></span>}
                                </div>
                                <p className="text-[11px] text-gray-500 dark:text-gray-400 mt-0.5 line-clamp-2">{n.message}</p>
                                <p className="text-[10px] text-gray-400 dark:text-gray-500 mt-1">{formatTime(n.created_at)}</p>
                              </div>
                            </button>
                          );
                        })
                      )}
                    </div>

                    <Link
                      to="/dashboard/notifikasi"
                      onClick={() => setShowNotif(false)}
                      className="block w-full px-4 py-2.5 text-center text-xs font-semibold text-blue-600 dark:text-blue-400 hover:bg-gray-50 dark:hover:bg-gray-800 border-t border-gray-100 dark:border-gray-800"
                    >
                      Lihat Semua
                    </Link>
                  </div>
                </>
              )}
            </div>

            {/* Divider */}
            <div className="w-px h-7 bg-gray-200 dark:bg-gray-700 mx-1 hidden md:block"></div>

            {/* Profile */}
            <div className="relative">
              <button
                onClick={() => { setShowProfile((v) => !v); setShowNotif(false); }}
                className="flex items-center gap-2 pl-1 pr-2 py-1 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-800 transition-colors"
              >
                <div className="w-8 h-8 rounded-lg bg-blue-600 text-white flex items-center justify-center font-bold text-[13px]">
                  {profile?.full_name ? profile.full_name.charAt(0) : 'A'}
                </div>
                <div className="hidden lg:block text-left">
                  <p className="text-[13px] font-semibold text-gray-800 dark:text-gray-200 leading-tight">{profile?.full_name || 'Admin'}</p>
                  <p className="text-[11px] text-gray-400 dark:text-gray-500 leading-tight">{roleLabel}</p>
                </div>
                <span className="material-symbols-outlined text-gray-400 text-[16px]">expand_more</span>
              </button>

              {showProfile && (
                <>
                  <div className="fixed inset-0 z-40" onClick={() => setShowProfile(false)}></div>
                  <div className="absolute right-0 top-full mt-1 w-48 bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-xl shadow-lg py-1 z-50 animate-[slideDown_140ms_ease-out]">
                    <Link to="/dashboard/settings" onClick={() => setShowProfile(false)} className="flex items-center gap-2 px-4 py-2 text-sm text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-gray-700">
                      <span className="material-symbols-outlined text-[18px]">person</span>
                      Profil Saya
                    </Link>
                    <Link to="/dashboard/settings" onClick={() => setShowProfile(false)} className="flex items-center gap-2 px-4 py-2 text-sm text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-gray-700">
                      <span className="material-symbols-outlined text-[18px]">settings</span>
                      Pengaturan
                    </Link>
                    <div className="border-t border-gray-100 dark:border-gray-700 my-1"></div>
                    <button
                      onClick={() => { setShowProfile(false); setShowLogoutConfirm(true); }}
                      className="w-full flex items-center gap-2 px-4 py-2 text-sm text-red-600 dark:text-red-400 hover:bg-red-50 dark:hover:bg-red-900/20"
                    >
                      <span className="material-symbols-outlined text-[18px]">logout</span>
                      Keluar
                    </button>
                  </div>
                </>
              )}
            </div>
          </div>
        </div>
      </header>

      <ConfirmDialog
        open={showLogoutConfirm}
        onClose={() => setShowLogoutConfirm(false)}
        onConfirm={() => { setShowLogoutConfirm(false); signOut(); }}
        title="Keluar Akun?"
        message="Anda akan keluar dari dashboard. Sesi saat ini akan diakhiri."
        confirmText="Ya, Keluar"
        cancelText="Batal"
        variant="danger"
        icon="logout"
      />
    </>
  );
};

export default Navbar;
