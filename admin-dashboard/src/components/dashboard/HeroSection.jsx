import React from 'react';

const HeroSection = () => {
  return (
    <div className="bg-primary text-on-primary rounded-xl p-6 relative overflow-hidden shadow-lg border border-primary-container flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
      {/* Background Decorative */}
      <div className="absolute -right-10 -top-10 w-48 h-48 bg-secondary/30 rounded-full blur-3xl pointer-events-none"></div>
      
      <div className="flex flex-col gap-2 z-10">
        <div className="flex items-center gap-2">
          <span className="font-label-sm text-label-sm text-primary-fixed-dim uppercase tracking-wider">Total Revenue (May 2026)</span>
          <div className="flex items-center gap-1 bg-surface/10 px-2 py-0.5 rounded-full border border-surface/20">
            <span className="w-2 h-2 rounded-full bg-secondary animate-pulse"></span>
            <span className="text-[10px] font-medium text-secondary-fixed">Live</span>
          </div>
        </div>
        <h2 className="text-4xl md:text-5xl font-h1 font-bold tracking-tight">Rp 12.450.000.000</h2>
        <p className="text-body-md text-primary-fixed-dim">
          <span className="text-secondary-fixed font-medium">+15.2%</span> compared to last month
        </p>
      </div>

      <div className="z-10 flex gap-3">
        <button className="px-4 py-2 bg-secondary text-on-secondary rounded-lg font-label-sm font-medium hover:bg-secondary-container hover:text-on-secondary-container transition-colors shadow-sm flex items-center gap-2">
          <span className="material-symbols-outlined text-[18px]">account_balance_wallet</span>
          View Details
        </button>
      </div>
    </div>
  );
};

export default HeroSection;
