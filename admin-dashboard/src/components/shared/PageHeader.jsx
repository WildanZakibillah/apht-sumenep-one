import React from 'react';

const PageHeader = ({ title, description, children }) => (
  <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
    <div>
      <h2 className="text-xl font-bold text-gray-900 dark:text-white">{title}</h2>
      {description && <p className="text-sm text-gray-500 dark:text-gray-400 mt-0.5">{description}</p>}
    </div>
    {children && <div className="flex items-center gap-3 flex-wrap">{children}</div>}
  </div>
);

export default PageHeader;
