import React from 'react';

const EmptyState = ({ icon = 'inbox', title = 'Tidak ada data', description = '', action, actionLabel }) => (
  <div className="flex flex-col items-center justify-center py-16 px-4">
    <div className="w-16 h-16 rounded-2xl bg-gray-100 dark:bg-gray-800 flex items-center justify-center mb-4">
      <span className="material-symbols-outlined text-gray-400 dark:text-gray-500 text-[32px]">{icon}</span>
    </div>
    <h3 className="text-sm font-semibold text-gray-700 dark:text-gray-300">{title}</h3>
    {description && <p className="text-xs text-gray-400 dark:text-gray-500 mt-1 text-center max-w-xs">{description}</p>}
    {action && (
      <button onClick={action} className="mt-4 px-4 py-2 bg-blue-600 text-white text-xs font-semibold rounded-lg hover:bg-blue-700 transition-colors">
        {actionLabel || 'Tambah Data'}
      </button>
    )}
  </div>
);

export default EmptyState;
