import React, { useState } from 'react';
import { NavLink } from 'react-router-dom';
import { useAuth } from '../../hooks/useAuth';
import { useNotifications } from '../../hooks/useNotifications';
import { useAppContext } from '../../context/AppContext';
import { useRoleAccess } from '../../hooks/useRoleAccess';
import ConfirmDialog from '../shared/ConfirmDialog';
import logoApht from '../../assets/Logo apht.png';

export const getNavSections = (isFactoryScoped) => {
  const sections = [
    {
      title: 'OVERVIEW',
      items: [
        { id: 'dashboard', icon: 'dashboard', label: 'Beranda', path: '/dashboard' },
        ...(!isFactoryScoped ? [{ id: 'factory', icon: 'domain', label: 'Data Pabrik', path: '/dashboard/data-pabrik' }] : []),
      ],
    },
    {
      title: 'OPERASIONAL',
      items: [
        { id: 'production', icon: 'inventory_2', label: 'Data Produksi', path: '/dashboard/data-produksi' },
        { id: 'excise', icon: 'confirmation_number', label: 'Pantau Cukai', path: '/dashboard/pantau-cukai' },
        { id: 'cukai-requests', icon: 'assignment', label: 'Pengajuan Cukai', path: '/dashboard/pengajuan-cukai' },
        { id: 'marketing', icon: 'storefront', label: 'Data Pemasaran', path: '/dashboard/data-pemasaran' },
      ],
    },
    {
      title: 'MANAJEMEN',
      items: [
        { id: 'master', icon: 'category', label: 'Data Master', path: '/dashboard/data-master' },
        ...(!isFactoryScoped ? [{ id: 'users', icon: 'people', label: 'Manajemen User', path: '/dashboard/manajemen-pengguna' }] : []),
        { id: 'notifications', icon: 'notifications_active', label: 'Notifikasi', path: '/dashboard/notifikasi', badge: 'notif' },
        { id: 'settings', icon: 'settings_suggest', label: 'Pengaturan', path: '/dashboard/settings' },
      ],
    },
  ];
  return sections;
};

const Sidebar = () => {
  const { signOut } = useAuth();
  const { unreadCount } = useNotifications();
  const { sidebarCollapsed, setSidebarCollapsed } = useAppContext();
  const { roleLabel, isFactoryScoped } = useRoleAccess();
  const [showLogoutConfirm, setShowLogoutConfirm] = useState(false);

  const collapsed = sidebarCollapsed;
  const width = collapsed ? 'w-[72px]' : 'w-[260px]';
  const navSections = getNavSections(isFactoryScoped);

  return (
    <>
      <nav className={`bg-white dark:bg-gray-900 ${width} h-screen fixed left-0 top-0 flex flex-col z-40 border-r border-gray-200 dark:border-gray-800 transition-all duration-200`}>
        {/* Logo + Toggle */}
        <div className="px-3 py-4 border-b border-gray-200 dark:border-gray-800 flex items-center justify-between">
          <div className={`flex items-center gap-3 ${collapsed ? 'justify-center w-full' : ''}`}>
            <img src={logoApht} alt="APHT" className="w-9 h-9 rounded-lg object-contain" />
            {!collapsed && (
              <div>
                <h2 className="text-gray-900 dark:text-white font-bold text-[15px] tracking-tight leading-tight">APHT SUMENEP</h2>
                <p className="text-gray-400 dark:text-gray-500 text-[11px] font-medium">{roleLabel} Panel</p>
              </div>
            )}
          </div>
          {!collapsed && (
            <button
              onClick={() => setSidebarCollapsed(true)}
              className="w-7 h-7 rounded-lg flex items-center justify-center text-gray-400 hover:text-gray-600 dark:hover:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors"
            >
              <span className="material-symbols-outlined text-[18px]">chevron_left</span>
            </button>
          )}
        </div>

        {/* Expand button when collapsed */}
        {collapsed && (
          <div className="px-3 py-2 flex justify-center">
            <button
              onClick={() => setSidebarCollapsed(false)}
              className="w-8 h-8 rounded-lg flex items-center justify-center text-gray-400 hover:text-gray-600 dark:hover:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors"
            >
              <span className="material-symbols-outlined text-[18px]">chevron_right</span>
            </button>
          </div>
        )}

        {/* Navigation */}
        <div className="flex-1 overflow-y-auto py-4 px-2 custom-scrollbar space-y-5">
          {navSections.map((section) => (
            <div key={section.title}>
              {!collapsed && (
                <p className="text-[10px] font-bold text-gray-400 dark:text-gray-600 uppercase tracking-[0.15em] px-3 mb-2">{section.title}</p>
              )}
              <div className="space-y-0.5">
                {section.items.map((item) => (
                  <NavLink
                    key={item.id}
                    to={item.path}
                    end={item.path === '/dashboard'}
                    title={collapsed ? item.label : undefined}
                    className={({ isActive }) =>
                      `flex items-center ${collapsed ? 'justify-center' : ''} gap-3 ${collapsed ? 'px-0 py-2.5' : 'px-3 py-2.5'} rounded-xl text-[13px] font-medium transition-all duration-150 relative ${
                        isActive
                          ? 'bg-indigo-50 dark:bg-indigo-900/30 text-indigo-600 dark:text-indigo-300 border-l-[3px] border-indigo-600 dark:border-indigo-400' + (collapsed ? ' pl-[9px]' : ' pl-[9px]')
                          : 'text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white hover:bg-gray-100 dark:hover:bg-gray-800'
                      }`
                    }
                  >
                    {({ isActive }) => (
                      <>
                        <span className="material-symbols-outlined text-[20px]" style={{ fontVariationSettings: isActive ? "'FILL' 1" : "'FILL' 0" }}>
                          {item.icon}
                        </span>
                        {!collapsed && <span className="flex-1">{item.label}</span>}
                        {!collapsed && item.badge === 'notif' && unreadCount > 0 && (
                          <span className="min-w-[20px] h-[20px] px-1.5 bg-red-500 text-white text-[10px] font-bold rounded-full flex items-center justify-center">
                            {unreadCount > 99 ? '99+' : unreadCount}
                          </span>
                        )}
                        {collapsed && item.badge === 'notif' && unreadCount > 0 && (
                          <span className="absolute -top-0.5 -right-0.5 w-4 h-4 bg-red-500 text-white text-[8px] font-bold rounded-full flex items-center justify-center">
                            {unreadCount > 9 ? '9+' : unreadCount}
                          </span>
                        )}
                      </>
                    )}
                  </NavLink>
                ))}
              </div>
            </div>
          ))}
        </div>

        {/* Bottom: Logout */}
        <div className="border-t border-gray-200 dark:border-gray-800 p-2">
          <button
            onClick={() => setShowLogoutConfirm(true)}
            title={collapsed ? 'Keluar' : undefined}
            className={`w-full flex items-center ${collapsed ? 'justify-center' : ''} gap-3 px-3 py-2.5 rounded-xl text-[13px] font-medium text-red-500 dark:text-red-400 hover:bg-red-50 dark:hover:bg-red-900/20 transition-all duration-150`}
          >
            <span className="material-symbols-outlined text-[20px]">logout</span>
            {!collapsed && <span>Keluar</span>}
          </button>
        </div>
      </nav>

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

export default Sidebar;
