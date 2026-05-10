import React from 'react';

const FAB = () => {
  return (
    <button className="fixed bottom-6 left-1/2 -translate-x-1/2 w-14 h-14 bg-primary text-on-primary rounded-full shadow-lg flex items-center justify-center z-50 hover:bg-primary-container transition-transform active:scale-95">
      <span className="material-symbols-outlined text-[28px]">add</span>
    </button>
  );
};

export default FAB;
