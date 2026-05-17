import React from 'react';

/**
 * Reusable search bar — pill shape, border pill, no inner rectangle on focus.
 */
const SearchBar = ({
  value,
  onChange,
  placeholder = 'Cari...',
  className = '',
}) => {
  return (
    <div
      className={`flex items-center gap-3 bg-gray-100 dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-full px-5 h-11 w-full focus-within:border-blue-400 dark:focus-within:border-blue-500 transition-colors ${className}`}
    >
      <span className="material-symbols-outlined text-gray-400 dark:text-gray-500 text-[20px] flex-shrink-0">search</span>
      <input
        value={value}
        onChange={onChange}
        placeholder={placeholder}
        style={{ outline: 'none', boxShadow: 'none', border: 'none', background: 'transparent' }}
        className="outline-none border-none shadow-none ring-0 focus:outline-none focus:ring-0 focus:border-none bg-transparent text-sm text-gray-700 dark:text-gray-200 w-full placeholder-gray-400 dark:placeholder-gray-500"
      />
    </div>
  );
};

export default SearchBar;
