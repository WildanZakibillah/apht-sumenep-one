import React from 'react';
import { NavLink } from 'react-router-dom';
import { useRoleAccess } from '../../hooks/useRoleAccess';

const MobileBottomNav = () => {
  const { isFactoryScoped } = useRoleAccess();

  const items = [
    { icon: 'space_dashboard', label: 'Beranda', path: '/dashboard' },
    { icon: 'monitoring', label: 'Cukai', path: '/dashboard/pantau-cukai' },
    { icon: 'request_page', label: 'Pengajuan', path: '/dashboard/pengajuan-cukai' },
    ...(!isFactoryScoped ? [{ icon: 'factory', label: 'Pabrik', path: '/dashboard/data-pabrik' }] : []),
    { icon: 'person', label: 'Akun', path: '/dashboard/settings' },
  ];

  return (
    <div className="fixed bottom-0 left-0 w-full bg-white border-t border-gray-200 z-40 lg:hidden">
      <div className="flex justify-between items-center h-16 px-4">
        {items.map((item) => (
          <NavLink
            key={item.path}
            to={item.path}
            end={item.path === '/dashboard'}
            className={({ isActive }) =>
              `flex flex-col items-center gap-0.5 px-2 py-1 rounded-lg transition-colors ${
                isActive ? 'text-blue-600' : 'text-gray-400'
              }`
            }
          >
            {({ isActive }) => (
              <>
                <span className="material-symbols-outlined text-[22px]" style={{ fontVariationSettings: isActive ? "'FILL' 1" : "'FILL' 0" }}>
                  {item.icon}
                </span>
                <span className="text-[10px] font-medium">{item.label}</span>
              </>
            )}
          </NavLink>
        ))}
      </div>
    </div>
  );
};

export default MobileBottomNav;
