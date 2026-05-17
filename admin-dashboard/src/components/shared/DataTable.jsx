import React from 'react';
import { SkeletonTable } from './Skeleton';
import EmptyState from './EmptyState';

const DataTable = ({ columns, data, loading, emptyIcon, emptyTitle, emptyDescription, renderRow, pagination }) => {
  if (loading) return <SkeletonTable rows={6} cols={columns.length} />;

  return (
    <div className="bg-white dark:bg-gray-900 rounded-xl border border-gray-200 dark:border-gray-800 overflow-hidden">
      <div className="overflow-x-auto">
        <table className="w-full text-left">
          <thead>
            <tr className="bg-gray-50 dark:bg-gray-800/50 border-b border-gray-100 dark:border-gray-800">
              {columns.map((col, i) => (
                <th key={i} className={`px-5 py-3.5 text-[11px] font-bold text-gray-400 dark:text-gray-500 uppercase tracking-wider ${col.align === 'center' ? 'text-center' : col.align === 'right' ? 'text-right' : ''}`}>
                  {col.label}
                </th>
              ))}
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-50 dark:divide-gray-800">
            {data.length === 0 ? (
              <tr>
                <td colSpan={columns.length}>
                  <EmptyState icon={emptyIcon} title={emptyTitle} description={emptyDescription} />
                </td>
              </tr>
            ) : (
              data.map((item, i) => renderRow(item, i))
            )}
          </tbody>
        </table>
      </div>

      {/* Pagination */}
      {pagination && data.length > 0 && (
        <div className="px-5 py-3.5 border-t border-gray-100 dark:border-gray-800 flex items-center justify-between">
          <span className="text-xs text-gray-400 dark:text-gray-500">{pagination.label}</span>
          <div className="flex items-center gap-1">
            <button
              disabled={!pagination.hasPrev}
              className="px-3 py-1.5 rounded-lg border border-gray-200 dark:border-gray-700 hover:bg-gray-50 dark:hover:bg-gray-800 text-xs font-medium text-gray-600 dark:text-gray-400 disabled:opacity-40 transition-colors"
            >
              Prev
            </button>
            <span className="px-3 py-1.5 rounded-lg bg-blue-600 text-white text-xs font-bold">{pagination.current}</span>
            <button
              disabled={!pagination.hasNext}
              className="px-3 py-1.5 rounded-lg border border-gray-200 dark:border-gray-700 hover:bg-gray-50 dark:hover:bg-gray-800 text-xs font-medium text-gray-600 dark:text-gray-400 disabled:opacity-40 transition-colors"
            >
              Next
            </button>
          </div>
        </div>
      )}
    </div>
  );
};

export default DataTable;
