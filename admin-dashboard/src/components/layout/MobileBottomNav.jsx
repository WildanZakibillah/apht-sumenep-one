import React from 'react';
import { NavLink } from 'react-router-dom';

const MobileBottomNav = () => {
  return (
    <div className="fixed bottom-0 left-0 w-full bg-surface border-t border-outline-variant z-40 pb-safe">
      <div className="flex justify-between items-center h-16 px-6">
        <NavLink to="/dashboard" end className={({ isActive }) => `flex flex-col items-center gap-1 ${isActive ? 'text-primary' : 'text-on-surface-variant'}`}>
          <span className="material-symbols-outlined text-[24px]" style={{ fontVariationSettings: "'FILL' 1" }}>dashboard</span>
          <span className="text-[10px] font-medium">Beranda</span>
        </NavLink>
        
        <NavLink to="/dashboard/laporan-masuk" className={({ isActive }) => `flex flex-col items-center gap-1 pr-8 ${isActive ? 'text-primary' : 'text-on-surface-variant'}`}>
          <span className="material-symbols-outlined text-[24px]">description</span>
          <span className="text-[10px] font-medium">Laporan</span>
        </NavLink>

        <NavLink to="/dashboard/pantau-cukai" className={({ isActive }) => `flex flex-col items-center gap-1 pl-8 ${isActive ? 'text-primary' : 'text-on-surface-variant'}`}>
          <span className="material-symbols-outlined text-[24px]">analytics</span>
          <span className="text-[10px] font-medium">Cukai</span>
        </NavLink>

        <NavLink to="/dashboard/profil" className={({ isActive }) => `flex flex-col items-center gap-1 ${isActive ? 'text-primary' : 'text-on-surface-variant'}`}>
          <span className="material-symbols-outlined text-[24px]">person</span>
          <span className="text-[10px] font-medium">Profil</span>
        </NavLink>
      </div>
    </div>
  );
};

export default MobileBottomNav;
