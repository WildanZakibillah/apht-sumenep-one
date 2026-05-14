import React from 'react';
import { useAuth } from '../../hooks/useAuth';

const Navbar = () => {
  const { profile } = useAuth();

  return (
    <header className="bg-surface dark:bg-surface-dim border-b border-outline-variant dark:border-outline docked full-width top-0 sticky z-30">
      <div className="flex justify-between items-center w-full px-4 lg:px-lg py-sm">
        {/* Search Bar */}
        <div className="flex-1 max-w-md hidden md:block">
          <div className="relative flex items-center w-full h-10 rounded-full focus-within:shadow-sm bg-surface-container-low border border-outline-variant overflow-hidden">
            <div className="grid place-items-center h-full w-12 text-outline">
              <span className="material-symbols-outlined text-[20px]">search</span>
            </div>
            <input 
              className="peer h-full w-full outline-none text-body-md text-on-surface bg-transparent pr-sm" 
              id="search" 
              placeholder="Search factory or report..." 
              type="text" 
            />
          </div>
        </div>
        
        {/* Mobile menu icon (placeholder) */}
        <div className="md:hidden flex items-center">
            <h2 className="font-h3 text-h3 text-primary font-bold">APHT One</h2>
        </div>

        {/* Trailing Actions & Profile */}
        <div className="flex items-center gap-2 lg:gap-sm">
          <button className="w-10 h-10 flex items-center justify-center text-on-surface-variant hover:bg-surface-container-low dark:hover:bg-surface-container-high rounded-full transition-all active:opacity-80">
            <span className="material-symbols-outlined">notifications</span>
          </button>
          <button className="hidden md:flex w-10 h-10 items-center justify-center text-on-surface-variant hover:bg-surface-container-low dark:hover:bg-surface-container-high rounded-full transition-all active:opacity-80">
            <span className="material-symbols-outlined">apps</span>
          </button>
          
          <div className="hidden md:block w-px h-6 bg-outline-variant mx-xs"></div>
          
          <button className="flex items-center gap-xs pl-xs pr-sm py-1 rounded-full border border-outline-variant hover:bg-surface-container-low transition-all overflow-hidden">
            {profile?.avatar_url ? (
              <img src={profile.avatar_url} alt="Profile" className="w-8 h-8 rounded-full object-cover" />
            ) : (
              <div className="w-8 h-8 rounded-full bg-primary-container text-on-primary flex items-center justify-center font-bold text-[14px]">
                {profile?.full_name ? profile.full_name.charAt(0) : 'A'}
              </div>
            )}
            <span className="font-label-sm text-label-sm font-medium text-on-surface hidden lg:block ml-1">
              {profile?.full_name || 'Admin'}
            </span>
            <span className="material-symbols-outlined text-[16px] text-outline">arrow_drop_down</span>
          </button>
        </div>
      </div>
    </header>
  );
};

export default Navbar;
