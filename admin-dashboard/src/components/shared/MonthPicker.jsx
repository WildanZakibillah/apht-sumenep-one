import React, { useRef } from 'react';

/**
 * Reusable month picker — slim, rounded-xl.
 * Shows: filter icon + formatted label "Mei 2026" + chevron-down.
 * Clicking the visible label opens the native month picker (hidden input).
 *
 * Props:
 * - value: "YYYY-MM" string
 * - onChange: (e) => void  — receives standard input change event
 * - className?: string
 */
const MonthPicker = ({ value, onChange, className = '' }) => {
  const inputRef = useRef(null);

  const formatLabel = (v) => {
    if (!v) return '-';
    const [y, m] = v.split('-');
    const d = new Date(Number(y), Number(m) - 1, 1);
    return d.toLocaleDateString('id-ID', { month: 'long', year: 'numeric' });
  };

  const open = () => {
    const el = inputRef.current;
    if (!el) return;
    if (typeof el.showPicker === 'function') {
      try {
        el.showPicker();
        return;
      } catch (_) {
        // fall through to focus/click
      }
    }
    el.focus();
    el.click();
  };

  return (
    <button
      type="button"
      onClick={open}
      className={`group relative flex items-center gap-2 bg-white dark:bg-gray-900 border border-gray-100 dark:border-gray-800 shadow-sm hover:shadow rounded-xl px-3 h-10 transition-shadow ${className}`}
    >
      <span className="material-symbols-outlined text-blue-500 dark:text-blue-400 text-[18px]" style={{ fontVariationSettings: "'FILL' 1" }}>
        filter_alt
      </span>
      <span className="text-sm font-bold text-gray-800 dark:text-gray-100 whitespace-nowrap">
        {formatLabel(value)}
      </span>
      <span className="material-symbols-outlined text-gray-400 dark:text-gray-500 text-[18px] ml-1">expand_more</span>
      <input
        ref={inputRef}
        type="month"
        value={value}
        onChange={onChange}
        className="absolute inset-0 opacity-0 cursor-pointer"
        aria-label="Pilih bulan"
      />
    </button>
  );
};

export default MonthPicker;
