import React from 'react';
import Sidebar from './Sidebar';
import Navbar from './Navbar';
import MobileBottomNav from './MobileBottomNav';
import FAB from './FAB';

const MainLayout = ({ children }) => {
  return (
    <div className="bg-background text-on-surface font-body-md min-h-screen flex w-full">
      {/* Desktop Sidebar */}
      <div className="hidden lg:block">
        <Sidebar />
      </div>

      {/* Main Content Wrapper */}
      <div className="w-full lg:ml-[280px] lg:max-w-[calc(100%-280px)] flex flex-col min-h-screen">
        <Navbar />
        
        <main className="flex-1 p-4 lg:p-lg flex flex-col gap-lg bg-background w-full">
          {children}
        </main>
      </div>

      {/* Mobile Elements */}
      <div className="lg:hidden">
        <FAB />
        <MobileBottomNav />
      </div>
    </div>
  );
};

export default MainLayout;
