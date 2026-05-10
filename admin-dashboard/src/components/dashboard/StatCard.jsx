import React from 'react';

const StatCard = ({ title, value, subtitle, icon, trend, colorClass, trendIcon, trendClass }) => {
  return (
    <div className="bg-surface-container-lowest border border-outline-variant p-md rounded-xl flex flex-col gap-sm relative overflow-hidden">
      <div className="flex justify-between items-start">
        <span className="font-label-sm text-label-sm text-on-surface-variant uppercase tracking-wider">{title}</span>
        <div className={`w-8 h-8 rounded-full flex items-center justify-center ${colorClass}`}>
          <span className="material-symbols-outlined text-[18px]">{icon}</span>
        </div>
      </div>
      <div>
        <div className="font-h1 text-h1 text-on-surface">
          {value} <span className="font-body-lg text-body-lg text-outline font-normal">{subtitle}</span>
        </div>
      </div>
      <div className="flex items-center gap-xs mt-auto pt-sm border-t border-surface-variant">
        <span className={`material-symbols-outlined text-[16px] ${trendClass}`}>{trendIcon}</span>
        <span className={`font-label-sm text-label-sm ${trendClass}`}>{trend}</span>
      </div>
    </div>
  );
};

export default StatCard;
