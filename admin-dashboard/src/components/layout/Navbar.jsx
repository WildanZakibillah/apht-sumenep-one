import React, { useState, useMemo, useEffect, useCallback } from 'react';
import { Link, useNavigate, useLocation } from 'react-router-dom';
import { useAuth } from '../../hooks/useAuth';
import { useTheme } from '../../context/ThemeContext';
import { getNavSections } from './Sidebar';
import { useRoleAccess } from '../../hooks/useRoleAccess';
import ConfirmDialog from '../shared/ConfirmDialog';
import { supabase } from '../../lib/supabase';

const Navbar = () => {
  const { profile, signOut, ready } = useAuth();
  const { isDark, toggleTheme } = useTheme();
  const { roleLabel, isDirektur, isFactoryScoped, factoryId } = useRoleAccess();
  const location = useLocation();
  const navigate = useNavigate();
  const [showProfile, setShowProfile] = useState(false);
  const [showLogoutConfirm, setShowLogoutConfirm] = useState(false);
  const [showNotifications, setShowNotifications] = useState(false);
  const [pendingCukaiCount, setPendingCukaiCount] = useState(0);
  const [pendingOutgoingCount, setPendingOutgoingCount] = useState(0);
  const [seenCounts, setSeenCounts] = useState({ cukai: 0, outgoing: 0 });

  const fetchPendingCounts = useCallback(async () => {
    if (!ready) return;
    try {
      let cukaiQuery = supabase.from('cukai_requests').select('id', { count: 'exact', head: true }).eq('status', 'pending');
      if (isFactoryScoped && factoryId) {
        cukaiQuery = cukaiQuery.eq('factory_id', factoryId);
      }
      const { count: cCount, error: cErr } = await cukaiQuery;
      if (!cErr) setPendingCukaiCount(cCount || 0);

      let outgoingQuery = supabase.from('outgoing_goods').select('id', { count: 'exact', head: true }).eq('status', 'pending');
      if (isFactoryScoped && factoryId) {
        outgoingQuery = outgoingQuery.eq('factory_id', factoryId);
      }
      const { count: oCount, error: oErr } = await outgoingQuery;
      if (!oErr) setPendingOutgoingCount(oCount || 0);
    } catch (err) {
      console.error("Error fetching pending counts in Navbar:", err);
    }
  }, [ready, isFactoryScoped, factoryId]);

  useEffect(() => {
    if (!ready) return;
    fetchPendingCounts();

    const channel = supabase
      .channel('navbar-notifications-channel')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'cukai_requests' }, () => {
        fetchPendingCounts();
      })
      .on('postgres_changes', { event: '*', schema: 'public', table: 'outgoing_goods' }, () => {
        fetchPendingCounts();
      })
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [ready, fetchPendingCounts]);

  useEffect(() => {
    const stored = localStorage.getItem('apht_seen_counts');
    if (stored) {
      try {
        setSeenCounts(JSON.parse(stored));
      } catch (e) {
        console.error(e);
      }
    }
  }, []);

  // Sync seenCounts when pending counts drop
  useEffect(() => {
    let changed = false;
    const newSeen = { ...seenCounts };
    if (seenCounts.cukai > pendingCukaiCount) {
      newSeen.cukai = pendingCukaiCount;
      changed = true;
    }
    if (seenCounts.outgoing > pendingOutgoingCount) {
      newSeen.outgoing = pendingOutgoingCount;
      changed = true;
    }
    if (changed) {
      setSeenCounts(newSeen);
      localStorage.setItem('apht_seen_counts', JSON.stringify(newSeen));
    }
  }, [pendingCukaiCount, pendingOutgoingCount, seenCounts]);

  const unreadCukai = pendingCukaiCount > (seenCounts.cukai ?? 0) ? pendingCukaiCount - (seenCounts.cukai ?? 0) : 0;
  const unreadOutgoing = pendingOutgoingCount > (seenCounts.outgoing ?? 0) ? pendingOutgoingCount - (seenCounts.outgoing ?? 0) : 0;
  const totalUnread = unreadCukai + unreadOutgoing;

  const handleCukaiClick = () => {
    const newSeen = { ...seenCounts, cukai: pendingCukaiCount };
    setSeenCounts(newSeen);
    localStorage.setItem('apht_seen_counts', JSON.stringify(newSeen));
    setShowNotifications(false);
    navigate('/dashboard/pengajuan-cukai');
  };

  const handleOutgoingClick = () => {
    const newSeen = { ...seenCounts, outgoing: pendingOutgoingCount };
    setSeenCounts(newSeen);
    localStorage.setItem('apht_seen_counts', JSON.stringify(newSeen));
    setShowNotifications(false);
    navigate('/dashboard/data-pemasaran');
  };

  const handleMarkAllAsRead = () => {
    const newSeen = { cukai: pendingCukaiCount, outgoing: pendingOutgoingCount };
    setSeenCounts(newSeen);
    localStorage.setItem('apht_seen_counts', JSON.stringify(newSeen));
  };

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
            {/* Notification Bell */}
            <div className="relative">
              <button
                onClick={() => setShowNotifications((v) => !v)}
                className="w-9 h-9 flex items-center justify-center text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-white hover:bg-gray-100 dark:hover:bg-gray-800 rounded-lg transition-colors relative"
                title="Notifikasi"
                aria-label="Notifications"
              >
                <span className="material-symbols-outlined text-[22px]">notifications</span>
                {totalUnread > 0 && (
                  <span className="absolute top-1.5 right-1.5 w-4 h-4 bg-red-500 text-white rounded-full flex items-center justify-center text-[9px] font-bold">
                    {totalUnread}
                  </span>
                )}
              </button>

              {showNotifications && (
                <>
                  <div className="fixed inset-0 z-40" onClick={() => setShowNotifications(false)}></div>
                  <div className="absolute right-0 top-full mt-1.5 w-80 bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-xl shadow-lg py-2 z-50 animate-[slideDown_140ms_ease-out]">
                    <div className="px-4 py-2 border-b border-gray-100 dark:border-gray-700 flex justify-between items-center">
                      <span className="font-bold text-xs text-gray-850 dark:text-gray-200">Notifikasi</span>
                      {totalUnread > 0 && (
                        <button
                          onClick={handleMarkAllAsRead}
                          className="text-[10px] text-blue-600 dark:text-blue-400 hover:underline font-semibold"
                        >
                          Tandai dibaca semua
                        </button>
                      )}
                    </div>
                    <div className="max-h-64 overflow-y-auto">
                      {pendingCukaiCount === 0 && pendingOutgoingCount === 0 ? (
                        <div className="px-4 py-6 text-center text-xs text-gray-400 dark:text-gray-500">
                          Tidak ada pengajuan pending
                        </div>
                      ) : (
                        <div className="divide-y divide-gray-50 dark:divide-gray-750">
                          {pendingCukaiCount > 0 && (
                            <button
                              onClick={handleCukaiClick}
                              className={`w-full text-left px-4 py-2.5 hover:bg-gray-50 dark:hover:bg-gray-700/50 flex gap-3 items-start transition-colors ${unreadCukai > 0 ? 'bg-blue-50/20 dark:bg-blue-900/10' : ''}`}
                            >
                              <div className="w-8 h-8 rounded-lg bg-blue-50 dark:bg-blue-950 text-blue-600 dark:text-blue-400 flex items-center justify-center flex-shrink-0">
                                <span className="material-symbols-outlined text-[18px]">assignment</span>
                              </div>
                              <div className="flex-1 min-w-0">
                                <p className="text-xs font-bold text-gray-800 dark:text-gray-200">Pengajuan Cukai Baru</p>
                                <p className="text-[11px] text-gray-500 dark:text-gray-400 mt-0.5 leading-tight">Ada {pendingCukaiCount} pengajuan pita cukai pending.</p>
                              </div>
                              {unreadCukai > 0 && (
                                <div className="w-1.5 h-1.5 rounded-full bg-blue-600 self-center"></div>
                              )}
                            </button>
                          )}
                          {pendingOutgoingCount > 0 && (
                            <button
                              onClick={handleOutgoingClick}
                              className={`w-full text-left px-4 py-2.5 hover:bg-gray-50 dark:hover:bg-gray-700/50 flex gap-3 items-start transition-colors ${unreadOutgoing > 0 ? 'bg-emerald-50/20 dark:bg-emerald-900/10' : ''}`}
                            >
                              <div className="w-8 h-8 rounded-lg bg-emerald-50 dark:bg-emerald-950 text-emerald-600 dark:text-emerald-400 flex items-center justify-center flex-shrink-0">
                                <span className="material-symbols-outlined text-[18px]">storefront</span>
                              </div>
                              <div className="flex-1 min-w-0">
                                <p className="text-xs font-bold text-gray-800 dark:text-gray-200">Pengajuan Barang Keluar</p>
                                <p className="text-[11px] text-gray-500 dark:text-gray-400 mt-0.5 leading-tight">Ada {pendingOutgoingCount} pengajuan barang keluar pending.</p>
                              </div>
                              {unreadOutgoing > 0 && (
                                <div className="w-1.5 h-1.5 rounded-full bg-emerald-600 self-center"></div>
                              )}
                            </button>
                          )}
                        </div>
                      )}
                    </div>
                  </div>
                </>
              )}
            </div>

            {/* Theme Toggle */}
            <button
              onClick={toggleTheme}
              className="w-9 h-9 flex items-center justify-center text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-white hover:bg-gray-100 dark:hover:bg-gray-800 rounded-lg transition-colors"
              title={isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode'}
              aria-label="Toggle theme"
            >
              <span className="material-symbols-outlined text-[22px]">{isDark ? 'light_mode' : 'dark_mode'}</span>
            </button>

            {/* Divider */}
            <div className="w-px h-7 bg-gray-200 dark:bg-gray-700 mx-1 hidden md:block"></div>

            {/* Profile */}
            <div className="relative">
              <button
                onClick={() => setShowProfile((v) => !v)}
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
