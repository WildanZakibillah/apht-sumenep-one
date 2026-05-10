import React from 'react';

const ArchiveCard = ({ name, period, verifiedDate }) => {
  return (
    <div className="bg-surface-container-lowest border border-outline-variant rounded-xl p-5 flex flex-col gap-4 hover:shadow-sm transition-shadow">
      <div className="flex items-start gap-4">
        <div className="w-12 h-12 bg-primary-container/30 rounded-lg flex items-center justify-center shrink-0">
          <span className="material-symbols-outlined text-[24px] text-primary">folder</span>
        </div>
        <div>
          <h3 className="font-h3 text-[18px] font-bold text-on-surface">{name}</h3>
          <p className="font-body-md text-[14px] text-on-surface-variant mt-0.5">{period}</p>
        </div>
      </div>
      
      <div className="border-t border-dashed border-outline-variant my-1"></div>
      
      <div className="flex flex-col gap-3 text-sm">
        <div className="flex justify-between items-center">
          <span className="text-on-surface-variant text-[12px] font-medium">Status APHT</span>
          <div className="flex items-center gap-1 bg-[#e8f5e9] text-[#2e7d32] px-2 py-0.5 rounded text-[11px] font-bold border border-[#c8e6c9]">
            <span className="material-symbols-outlined text-[14px]">check_circle</span>
            APHT Stamp
          </div>
        </div>
        <div className="flex justify-between items-center">
          <span className="text-on-surface-variant text-[12px] font-medium">Tanggal Verifikasi</span>
          <span className="font-bold text-[13px] text-on-surface">{verifiedDate}</span>
        </div>
      </div>

      <div className="flex gap-3 mt-3">
        <button className="flex-1 flex items-center justify-center gap-2 border border-outline-variant rounded-lg py-2 font-label-sm text-[12px] font-semibold text-on-surface hover:bg-surface-container-low transition-colors">
           <span className="material-symbols-outlined text-[18px]">visibility</span>
           Preview
        </button>
        <button className="flex-1 flex items-center justify-center gap-2 bg-[#000051] text-white rounded-lg py-2 font-label-sm text-[12px] font-semibold hover:bg-[#1a237e] transition-colors shadow-sm">
           <span className="material-symbols-outlined text-[18px]">download</span>
           Unduh PDF
        </button>
      </div>
    </div>
  );
};

const ArsipDigital = () => {
  const archives = [
    { id: 1, name: 'PR. Karaoke', period: 'Mei 2026', verifiedDate: '05 Jun 2026' },
    { id: 2, name: 'PR. Sejahtera', period: 'April 2026', verifiedDate: '02 Mei 2026' },
    { id: 3, name: 'PR. Makmur Jaya', period: 'Mei 2026', verifiedDate: '06 Jun 2026' },
    { id: 4, name: 'PR. Bintang Lima', period: 'Maret 2026', verifiedDate: '01 Apr 2026' },
  ];

  return (
    <div className="flex flex-col gap-lg w-full max-w-container-max mx-auto p-4 lg:p-0">
      
      {/* Header */}
      <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4 border-b border-surface-variant pb-4">
        <div>
          <h1 className="font-h1 text-[28px] font-bold text-on-surface">Arsip Digital</h1>
          <p className="font-body-md text-on-surface-variant mt-1 max-w-[500px]">Kelola, saring, dan unduh rekapitulasi pelaporan pita cukai yang telah diverifikasi.</p>
        </div>
        <div className="flex items-center gap-3 w-full md:w-auto">
          <button className="flex-1 md:flex-none flex items-center justify-center gap-xs px-md py-sm border border-outline-variant bg-surface-container-lowest text-on-surface rounded-lg font-label-sm text-sm font-semibold hover:bg-surface-container-low transition-colors shadow-sm whitespace-nowrap">
            <span className="material-symbols-outlined text-[18px]">folder_zip</span>
            Download Bulk (ZIP)
          </button>
          <button className="flex-1 md:flex-none flex items-center justify-center gap-xs px-md py-sm bg-[#000051] text-white rounded-lg font-label-sm text-sm font-semibold hover:bg-[#1a237e] transition-colors shadow-sm whitespace-nowrap">
            <span className="material-symbols-outlined text-[18px]">drive_folder_upload</span>
            Export Gabungan APHT
          </button>
        </div>
      </div>

      {/* Filters */}
      <div className="bg-surface border border-outline-variant rounded-xl p-6 flex flex-col md:flex-row gap-6 items-end mt-2">
        <div className="flex flex-col gap-2 flex-1 w-full">
          <label className="font-label-sm text-[12px] text-on-surface-variant font-medium">Pabrik Rokok (Factory)</label>
          <div className="relative">
            <select className="w-full appearance-none px-4 py-2.5 bg-surface-container-lowest border border-outline-variant rounded-lg text-sm text-on-surface focus:outline-none focus:border-primary">
              <option>Semua Pabrik</option>
            </select>
            <span className="material-symbols-outlined absolute right-3 top-1/2 -translate-y-1/2 text-outline text-[20px] pointer-events-none">expand_more</span>
          </div>
        </div>
        <div className="flex flex-col gap-2 flex-1 w-full">
          <label className="font-label-sm text-[12px] text-on-surface-variant font-medium">Dari Bulan</label>
          <div className="relative">
            <input type="text" placeholder="-- --- ----" className="w-full px-4 py-2.5 bg-surface-container-lowest border border-outline-variant rounded-lg text-sm text-on-surface focus:outline-none focus:border-primary placeholder-outline" />
            <span className="material-symbols-outlined absolute right-3 top-1/2 -translate-y-1/2 text-outline text-[18px] pointer-events-none">calendar_month</span>
          </div>
        </div>
        <div className="flex flex-col gap-2 flex-1 w-full">
          <label className="font-label-sm text-[12px] text-on-surface-variant font-medium">Sampai Bulan</label>
          <div className="relative">
            <input type="text" placeholder="-- --- ----" className="w-full px-4 py-2.5 bg-surface-container-lowest border border-outline-variant rounded-lg text-sm text-on-surface focus:outline-none focus:border-primary placeholder-outline" />
            <span className="material-symbols-outlined absolute right-3 top-1/2 -translate-y-1/2 text-outline text-[18px] pointer-events-none">calendar_month</span>
          </div>
        </div>
        <button className="px-6 py-2.5 bg-[#8c9eff] hover:bg-[#534bae] text-white rounded-lg text-sm font-semibold transition-colors w-full md:w-auto shadow-sm">
          Terapkan Filter
        </button>
      </div>

      {/* Grid of Archive Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-6 mt-4">
         {archives.map(archive => (
           <ArchiveCard key={archive.id} {...archive} />
         ))}
      </div>

      {/* Pagination */}
      <div className="flex justify-center mt-12 mb-8">
        <div className="flex items-center gap-2">
          <button className="w-10 h-10 border border-outline-variant rounded bg-surface hover:bg-surface-container-low flex items-center justify-center text-on-surface-variant">
             <span className="material-symbols-outlined text-[18px]">chevron_left</span>
          </button>
          <button className="w-10 h-10 border border-[#000051] rounded bg-[#000051] text-white flex items-center justify-center font-bold">1</button>
          <button className="w-10 h-10 border border-outline-variant rounded bg-surface hover:bg-surface-container-low flex items-center justify-center text-on-surface">2</button>
          <button className="w-10 h-10 border border-outline-variant rounded bg-surface hover:bg-surface-container-low flex items-center justify-center text-on-surface">3</button>
          <button className="w-10 h-10 border border-outline-variant rounded bg-surface hover:bg-surface-container-low flex items-center justify-center text-on-surface-variant">
             <span className="material-symbols-outlined text-[18px]">chevron_right</span>
          </button>
        </div>
      </div>

    </div>
  );
};

export default ArsipDigital;
