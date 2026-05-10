import React from 'react';
import { NavLink } from 'react-router-dom';

const navItems = [
  { id: 'dashboard', icon: 'dashboard', label: 'Beranda', path: '/dashboard' },
  { id: 'factory', icon: 'factory', label: 'Data Pabrik', path: '/dashboard/data-pabrik' },
  { id: 'incoming', icon: 'description', label: 'Laporan Masuk', path: '/dashboard/laporan-masuk' },
  { id: 'excise', icon: 'analytics', label: 'Pantau Cukai', path: '/dashboard/pantau-cukai' },
  { id: 'marketing', icon: 'trending_up', label: 'Data Pemasaran', path: '/dashboard/data-pemasaran' },
  { id: 'master', icon: 'database', label: 'Data Master', path: '/dashboard/data-master' },
  { id: 'archive', icon: 'folder_open', label: 'Arsip Digital', path: '/dashboard/arsip-digital' },
  { id: 'users', icon: 'people', label: 'Manajemen Pengguna', path: '/dashboard/manajemen-pengguna' },
];

const Sidebar = () => {
  return (
    <nav className="bg-primary dark:bg-on-background w-[280px] h-screen fixed left-0 top-0 border-r border-outline-variant dark:border-outline flex flex-col z-40">
      {/* Header */}
      <div className="p-lg border-b border-primary-container">
        <div className="flex items-center gap-sm mb-xs">
          <div className="w-8 h-8 rounded bg-secondary-fixed flex items-center justify-center">
            <span className="material-symbols-outlined text-primary text-[20px]" style={{ fontVariationSettings: "'FILL' 1" }}>admin_panel_settings</span>
          </div>
          <h2 className="font-h2 text-h2 text-on-primary dark:text-primary-fixed-dim font-bold tracking-tight">APHT Sumenep One</h2>
        </div>
        <p className="font-label-sm text-label-sm text-primary-fixed-dim">Admin Portal</p>
      </div>

      {/* Navigation Links */}
      <div className="flex-1 overflow-y-auto py-md flex flex-col gap-xs px-sm custom-scrollbar">
        {navItems.map((item) => (
          <NavLink
            key={item.id}
            to={item.path}
            end={item.path === '/dashboard'}
            className={({ isActive }) =>
              `flex items-center gap-sm px-md py-sm transition-colors rounded-r-DEFAULT border-l-4 ${isActive
                ? 'bg-secondary dark:bg-secondary-container text-on-secondary dark:text-on-secondary-container border-secondary-fixed shadow-sm'
                : 'text-primary-fixed-dim hover:text-on-primary hover:bg-primary-container dark:hover:bg-surface-container-highest border-transparent'
              }`
            }
          >
            {({ isActive }) => (
              <>
                <span className="material-symbols-outlined" style={{ fontVariationSettings: isActive ? "'FILL' 1" : "'FILL' 0" }}>
                  {item.icon}
                </span>
                <span className="font-body-md text-body-md font-medium">{item.label}</span>
              </>
            )}
          </NavLink>
        ))}

        <NavLink
          to="/dashboard/settings"
          className={({ isActive }) =>
            `flex items-center gap-sm px-md py-sm transition-colors rounded-r-DEFAULT border-l-4 mt-auto ${isActive
              ? 'bg-secondary dark:bg-secondary-container text-on-secondary dark:text-on-secondary-container border-secondary-fixed shadow-sm'
              : 'text-primary-fixed-dim hover:text-on-primary hover:bg-primary-container dark:hover:bg-surface-container-highest border-transparent'
            }`
          }
        >
          <span className="material-symbols-outlined">settings</span>
          <span className="font-body-md text-body-md font-medium">Pengaturan Akun</span>
        </NavLink>
      </div>
    </nav>
  );
};

export default Sidebar;
