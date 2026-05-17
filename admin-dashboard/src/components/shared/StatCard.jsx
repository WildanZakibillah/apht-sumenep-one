import React from 'react';

const colorMap = {
  blue: {
    bg: 'bg-gradient-to-br from-blue-100/80 to-blue-50 dark:from-blue-900/40 dark:to-blue-900/20',
    iconBg: 'bg-blue-200/70 dark:bg-blue-800/50',
    text: 'text-blue-600 dark:text-blue-300',
    border: 'border-blue-200/60 dark:border-blue-800/50',
    decor: 'text-blue-300/30 dark:text-blue-700/20',
  },
  green: {
    bg: 'bg-gradient-to-br from-emerald-100/80 to-emerald-50 dark:from-emerald-900/40 dark:to-emerald-900/20',
    iconBg: 'bg-emerald-200/70 dark:bg-emerald-800/50',
    text: 'text-emerald-600 dark:text-emerald-300',
    border: 'border-emerald-200/60 dark:border-emerald-800/50',
    decor: 'text-emerald-300/30 dark:text-emerald-700/20',
  },
  orange: {
    bg: 'bg-gradient-to-br from-amber-100/80 to-orange-50 dark:from-orange-900/40 dark:to-orange-900/20',
    iconBg: 'bg-amber-200/70 dark:bg-orange-800/50',
    text: 'text-amber-600 dark:text-amber-300',
    border: 'border-amber-200/60 dark:border-orange-800/50',
    decor: 'text-amber-300/30 dark:text-orange-700/20',
  },
  red: {
    bg: 'bg-gradient-to-br from-rose-100/80 to-red-50 dark:from-red-900/40 dark:to-red-900/20',
    iconBg: 'bg-rose-200/70 dark:bg-red-800/50',
    text: 'text-rose-500 dark:text-rose-300',
    border: 'border-rose-200/60 dark:border-red-800/50',
    decor: 'text-rose-300/30 dark:text-red-700/20',
  },
  purple: {
    bg: 'bg-gradient-to-br from-violet-100/80 to-purple-50 dark:from-purple-900/40 dark:to-purple-900/20',
    iconBg: 'bg-violet-200/70 dark:bg-purple-800/50',
    text: 'text-violet-600 dark:text-violet-300',
    border: 'border-violet-200/60 dark:border-purple-800/50',
    decor: 'text-violet-300/30 dark:text-purple-700/20',
  },
  indigo: {
    bg: 'bg-gradient-to-br from-indigo-100/80 to-indigo-50 dark:from-indigo-900/40 dark:to-indigo-900/20',
    iconBg: 'bg-indigo-200/70 dark:bg-indigo-800/50',
    text: 'text-indigo-600 dark:text-indigo-300',
    border: 'border-indigo-200/60 dark:border-indigo-800/50',
    decor: 'text-indigo-300/30 dark:text-indigo-700/20',
  },
};

const StatCard = ({ icon, label, value, suffix, trend, trendUp, color = 'blue', className = '' }) => {
  const colors = colorMap[color] || colorMap.blue;

  return (
    <div className={`relative overflow-hidden rounded-xl border ${colors.border} ${colors.bg} p-5 flex flex-col gap-3 hover:shadow-lg hover:scale-[1.02] dark:hover:shadow-gray-900/50 transition-all duration-200 ${className}`}>
      {/* Decorative background element */}
      <div className="absolute -right-3 -bottom-3 pointer-events-none">
        <span className={`material-symbols-outlined text-[72px] ${colors.decor}`} style={{ fontVariationSettings: "'FILL' 1" }}>
          {icon}
        </span>
      </div>
      {/* Decorative circle */}
      <div className={`absolute -top-6 -right-6 w-20 h-20 rounded-full ${colors.iconBg} opacity-30`}></div>

      <div className="flex items-center justify-between relative z-10">
        <div className={`w-11 h-11 rounded-xl flex items-center justify-center ${colors.iconBg} shadow-sm`}>
          <span className={`material-symbols-outlined text-[22px] ${colors.text}`} style={{ fontVariationSettings: "'FILL' 1" }}>{icon}</span>
        </div>
        {trend && (
          <span className={`text-[11px] font-bold flex items-center gap-0.5 px-2 py-0.5 rounded-full backdrop-blur-sm ${
            trendUp ? 'bg-emerald-100/80 dark:bg-emerald-900/40 text-emerald-600 dark:text-emerald-400' : 'bg-red-100/80 dark:bg-red-900/40 text-red-500 dark:text-red-400'
          }`}>
            <span className="material-symbols-outlined text-[12px]">{trendUp ? 'trending_up' : 'trending_down'}</span>
            {trend}
          </span>
        )}
      </div>
      <div className="relative z-10">
        <p className="text-[11px] font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider">{label}</p>
        <p className="text-2xl font-bold text-gray-900 dark:text-white mt-1">
          {value}
          {suffix && <span className="text-sm font-normal text-gray-400 dark:text-gray-500 ml-1">{suffix}</span>}
        </p>
      </div>
    </div>
  );
};

export default StatCard;
