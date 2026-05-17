import React from 'react';
import Sidebar from './Sidebar';
import Navbar from './Navbar';
import { useAppContext } from '../../context/AppContext';

const MainLayout = ({ children }) => {
  const { sidebarCollapsed } = useAppContext();
  const marginLeft = sidebarCollapsed ? 'lg:ml-[72px]' : 'lg:ml-[260px]';

  return (
    <div className="min-h-screen flex w-full bg-gray-50 dark:bg-gray-950">
      {/* Desktop Sidebar */}
      <div className="hidden lg:block">
        <Sidebar />
      </div>

      {/* Main Content */}
      <div className={`w-full ${marginLeft} flex flex-col min-h-screen transition-all duration-200`}>
        <Navbar />
        <main className="flex-1 p-5 lg:p-6">
          {children}
        </main>
      </div>
    </div>
  );
};

export default MainLayout;
