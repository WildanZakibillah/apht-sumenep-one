import React from 'react';

const ActivityList = () => {
  return (
    <div className="bg-surface-container-lowest border border-outline-variant rounded-xl flex flex-col h-[320px]">
      <div className="p-md border-b border-surface-variant flex justify-between items-center bg-surface-container-low rounded-t-xl">
        <h3 className="font-h3 text-h3 text-on-surface flex items-center gap-xs">
          <span className="material-symbols-outlined text-error">warning</span>
          ALERT PITA CUKAI
        </h3>
        <a className="font-label-sm text-label-sm text-secondary hover:underline" href="#">Lihat Semua</a>
      </div>
      <div className="flex-1 overflow-y-auto p-sm flex flex-col custom-scrollbar">
        {/* List Item Red */}
        <div className="flex items-center justify-between p-sm border-b border-surface-variant hover:bg-surface-container transition-colors">
          <div className="flex items-center gap-sm">
            <div className="w-2 h-2 rounded-full bg-error"></div>
            <span className="font-body-md text-body-md font-medium text-on-surface">Pabrik Bintang Mas (D)</span>
          </div>
          <span className="font-label-sm text-label-sm px-2 py-1 rounded bg-error-container text-error">Sisa &lt; 10%</span>
        </div>
        {/* List Item Yellow */}
        <div className="flex items-center justify-between p-sm border-b border-surface-variant hover:bg-surface-container transition-colors">
          <div className="flex items-center gap-sm">
            <div className="w-2 h-2 rounded-full bg-tertiary"></div>
            <span className="font-body-md text-body-md font-medium text-on-surface">Pabrik Jaya Abadi (A)</span>
          </div>
          <span className="font-label-sm text-label-sm px-2 py-1 rounded bg-tertiary-fixed text-on-tertiary-fixed">Mendekati Limit</span>
        </div>
        {/* List Item Green (Normal) */}
        <div className="flex items-center justify-between p-sm border-b border-surface-variant hover:bg-surface-container transition-colors">
          <div className="flex items-center gap-sm">
            <div className="w-2 h-2 rounded-full bg-secondary"></div>
            <span className="font-body-md text-body-md text-on-surface">Pabrik Sumber Rejeki (K)</span>
          </div>
          <span className="font-label-sm text-label-sm text-outline">Aman</span>
        </div>
        {/* List Item Green (Normal) */}
        <div className="flex items-center justify-between p-sm hover:bg-surface-container transition-colors">
          <div className="flex items-center gap-sm">
            <div className="w-2 h-2 rounded-full bg-secondary"></div>
            <span className="font-body-md text-body-md text-on-surface">Pabrik Makmur (F)</span>
          </div>
          <span className="font-label-sm text-label-sm text-outline">Aman</span>
        </div>
      </div>
    </div>
  );
};

export default ActivityList;
