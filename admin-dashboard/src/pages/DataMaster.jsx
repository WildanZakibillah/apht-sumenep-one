import React, { useState } from 'react';

const DataMaster = () => {
  const [isModalOpen, setIsModalOpen] = useState(false);

  const products = [
    { no: '1', name: 'SKM Filter Premium', category: 'Sigaret Kretek Mesin', categoryClass: 'bg-[#d9e2ff] text-[#001945]', isi: '16 Batang' },
    { no: '2', name: 'SKT Kretek Tangan', category: 'Sigaret Kretek Tangan', categoryClass: 'bg-[#ffdbd0] text-[#390c00]', isi: '12 Batang' },
    { no: '3', name: 'SPM Putih Mesin', category: 'Sigaret Putih Mesin', categoryClass: 'bg-[#e0e0ff] text-[#000767]', isi: '20 Batang' },
  ];

  return (
    <div className="flex flex-col gap-lg w-full max-w-container-max mx-auto p-4 lg:p-0 relative">
      
      {/* Page Header */}
      <div className="flex items-center justify-between pb-4">
        <h2 className="font-h1 text-[28px] font-bold text-on-surface">Data Master</h2>
        <button 
          onClick={() => setIsModalOpen(true)}
          className="bg-[#000051] text-white font-label-sm text-sm px-4 py-2 rounded-lg hover:bg-[#1a237e] transition-colors shadow-sm flex items-center gap-2"
        >
          <span className="material-symbols-outlined text-[18px]">add</span>
          Tambah
        </button>
      </div>

      {/* Horizontal Tabs */}
      <div className="border-b border-outline-variant flex gap-6 overflow-x-auto">
        <button className="px-2 py-3 font-body-md text-sm text-[#000051] font-bold border-b-2 border-[#000051] whitespace-nowrap">Jenis Produk</button>
        <button className="px-2 py-3 font-body-md text-sm text-on-surface-variant hover:text-on-surface transition-colors whitespace-nowrap">Merek</button>
        <button className="px-2 py-3 font-body-md text-sm text-on-surface-variant hover:text-on-surface transition-colors whitespace-nowrap">HJE</button>
        <button className="px-2 py-3 font-body-md text-sm text-on-surface-variant hover:text-on-surface transition-colors whitespace-nowrap">Wilayah</button>
        <button className="px-2 py-3 font-body-md text-sm text-on-surface-variant hover:text-on-surface transition-colors whitespace-nowrap">Golongan</button>
      </div>

      {/* Table Controls */}
      <div className="flex justify-between items-center bg-surface p-4 rounded-t-xl border border-outline-variant border-b-0 mt-4">
        <div className="relative w-full max-w-[300px]">
          <span className="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-outline text-[20px]">search</span>
          <input 
            className="w-full pl-10 pr-4 py-2 bg-surface-container-lowest border border-outline-variant rounded-lg font-body-md text-sm text-on-surface focus:border-primary focus:outline-none transition-all" 
            placeholder="Cari data..." 
            type="text" 
          />
        </div>
        <div className="flex gap-3">
          <button className="border border-outline-variant bg-surface-container-lowest text-on-surface font-body-md text-sm px-4 py-2 rounded-lg hover:bg-surface-container-low transition-colors flex items-center gap-2">
            <span className="material-symbols-outlined text-[18px]">filter_list</span>
            Filter
          </button>
        </div>
      </div>

      {/* Data Table */}
      <div className="bg-surface-container-lowest rounded-b-xl border border-outline-variant overflow-hidden shadow-sm mb-8">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse min-w-[800px]">
            <thead className="bg-surface-container-low/30">
              <tr>
                <th className="font-h3 text-sm text-on-surface py-3 px-4 border-b border-outline-variant w-[80px]">No</th>
                <th className="font-h3 text-sm text-on-surface py-3 px-4 border-b border-outline-variant">Nama Produk</th>
                <th className="font-h3 text-sm text-on-surface py-3 px-4 border-b border-outline-variant">Kategori</th>
                <th className="font-h3 text-sm text-on-surface py-3 px-4 border-b border-outline-variant text-right">Isi/Pak</th>
                <th className="font-h3 text-sm text-on-surface py-3 px-4 border-b border-outline-variant text-center w-[120px]">Actions</th>
              </tr>
            </thead>
            <tbody className="font-body-md text-sm text-on-surface">
              {products.map((item, index) => (
                <tr key={index} className="border-b border-outline-variant hover:bg-surface-container-lowest transition-colors">
                  <td className="py-3 px-4 text-on-surface-variant">{item.no}</td>
                  <td className="py-3 px-4 font-medium text-[#000051]">{item.name}</td>
                  <td className="py-3 px-4">
                    <span className={`${item.categoryClass} px-2 py-1 rounded text-[11px] font-medium`}>{item.category}</span>
                  </td>
                  <td className="py-3 px-4 text-right font-mono text-sm text-on-surface-variant">{item.isi}</td>
                  <td className="py-3 px-4 text-center">
                    <div className="flex justify-center gap-3 text-outline">
                      <button className="hover:text-primary transition-colors"><span className="material-symbols-outlined text-[20px]">edit</span></button>
                      <button className="hover:text-error transition-colors"><span className="material-symbols-outlined text-[20px]">delete</span></button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        
        {/* Pagination */}
        <div className="p-4 border-t border-outline-variant flex flex-col sm:flex-row justify-between items-center gap-4 text-xs text-on-surface-variant bg-surface-container-lowest">
          <span>Showing 1 to 3 of 12 entries</span>
          <div className="flex gap-2">
            <button className="px-3 py-1.5 border border-outline-variant rounded hover:bg-surface-container-low transition-colors disabled:opacity-50" disabled>Prev</button>
            <button className="px-3 py-1.5 border border-[#000051] rounded bg-[#000051] text-white font-medium">1</button>
            <button className="px-3 py-1.5 border border-outline-variant rounded hover:bg-surface-container-low transition-colors">2</button>
            <button className="px-3 py-1.5 border border-outline-variant rounded hover:bg-surface-container-low transition-colors">Next</button>
          </div>
        </div>
      </div>

      {/* Modal: Tambah Jenis Produk */}
      {isModalOpen && (
        <div className="fixed inset-0 bg-[#1b1b21]/60 z-50 flex items-center justify-center p-4">
          <div className="bg-surface-container-lowest rounded-xl shadow-lg w-full max-w-lg flex flex-col overflow-hidden animate-in fade-in zoom-in-95 duration-200">
            
            {/* Modal Header */}
            <div className="flex justify-between items-center p-6 border-b border-outline-variant bg-surface-container-lowest">
              <h3 className="font-h2 text-xl font-bold text-on-surface">Tambah Jenis Produk</h3>
              <button 
                onClick={() => setIsModalOpen(false)}
                className="text-outline hover:text-on-surface transition-colors p-1 rounded-full hover:bg-surface-container-low flex items-center justify-center"
              >
                <span className="material-symbols-outlined text-[24px]">close</span>
              </button>
            </div>
            
            {/* Modal Body */}
            <div className="p-6 flex flex-col gap-6 bg-surface-container-lowest">
              <div className="flex flex-col gap-2">
                <label className="font-label-sm text-xs text-on-surface font-semibold">Nama Produk *</label>
                <input 
                  className="w-full px-4 py-2 border border-outline-variant rounded-lg font-body-md text-sm text-on-surface focus:border-[#000051] focus:outline-none transition-all placeholder-outline" 
                  placeholder="Masukkan nama produk" 
                  type="text" 
                />
              </div>
              
              <div className="flex flex-col gap-2">
                <label className="font-label-sm text-xs text-on-surface font-semibold">Kategori *</label>
                <div className="relative">
                  <select className="w-full appearance-none px-4 py-2 border border-outline-variant rounded-lg font-body-md text-sm text-on-surface focus:border-[#000051] focus:outline-none transition-all bg-surface-container-lowest">
                    <option value="">Pilih Kategori</option>
                    <option value="skm">Sigaret Kretek Mesin (SKM)</option>
                    <option value="skt">Sigaret Kretek Tangan (SKT)</option>
                    <option value="spm">Sigaret Putih Mesin (SPM)</option>
                  </select>
                  <span className="material-symbols-outlined absolute right-3 top-1/2 -translate-y-1/2 text-outline pointer-events-none">expand_more</span>
                </div>
              </div>
              
              <div className="flex flex-col gap-2">
                <label className="font-label-sm text-xs text-on-surface font-semibold">Isi per Pak *</label>
                <div className="relative flex items-center">
                  <input 
                    className="w-full pl-4 pr-16 py-2 border border-outline-variant rounded-lg font-body-md text-sm text-on-surface focus:border-[#000051] focus:outline-none transition-all placeholder-outline" 
                    placeholder="0" 
                    type="number" 
                  />
                  <span className="absolute right-4 text-outline font-body-md text-sm">Batang</span>
                </div>
              </div>
            </div>
            
            {/* Modal Footer */}
            <div className="p-6 border-t border-outline-variant flex justify-end gap-3 bg-surface-container-lowest">
              <button 
                onClick={() => setIsModalOpen(false)}
                className="px-6 py-2 rounded-lg border border-outline-variant text-on-surface font-label-sm text-sm font-semibold hover:bg-surface-container-low transition-colors"
              >
                Batal
              </button>
              <button 
                className="px-6 py-2 rounded-lg bg-[#000051] text-white font-label-sm text-sm font-semibold hover:bg-[#1a237e] transition-colors shadow-sm"
              >
                Simpan Data
              </button>
            </div>
          </div>
        </div>
      )}

    </div>
  );
};

export default DataMaster;
